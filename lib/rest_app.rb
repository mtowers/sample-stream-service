require 'mongo'
require 'realself/feed'
require 'realself/handler'
require 'realself/stream'
require 'sinatra/base'
require 'sinatra/json'

require 'newsfeed'

class RestApp < Sinatra::Base

  # Number of feed entries to return if no count is specified
  DEFAULT_FEED_PAGE_SIZE = 10

  # max number of stream items to return when no interval is specified
  MAX_STREAM_ITEM_COUNT = 50

  helpers Sinatra::JSON

  include Mongo

  # app configuration
  configure do
    log_file        = ENV.fetch('HTTP_LOG', File.dirname(__FILE__) + '/../log/http.log')
    log_level       = 'production' == ENV['RACK_ENV'] ? ::Logger::INFO : ::Logger::DEBUG
    mongodb_host    = ENV.fetch('MONGODB_HOST', 'localhost:27017')
    mongodb_dbname  = 'sample-service'
    mongo_pool_size = ENV.fetch('MONGO_POOL_SIZE', 10).to_i
    rmq_url         = ENV.fetch('RABBITMQ_URL', 'amqp://guest:guest@localhost:5672')
    req_timeout     = ENV.fetch('CONNECTION_TIMEOUT', 5.0)

    # http logging
    enable    :logging
    file      = File.new log_file, 'a+'
    file.sync = true
    use Rack::CommonLogger, file

    # app logging
    RealSelf::logger        = ::Logger.new log_file
    RealSelf::logger.level  = log_level
    Mongo::Logger.logger    = RealSelf::logger

    # mongodb client
    mongo_client = Mongo::Client.new([mongodb_host],
                                     :database => mongodb_dbname,
                                     :min_pool_size => mongo_pool_size,
                                     :max_pool_size => mongo_pool_size * 2,
                                     :server_selection_timeout => req_timeout)

    # create our newsfeed manager
    set :mongo_db, mongo_client.database
    set :newsfeed, Newsfeed.new(mongo_db: mongo_client.database)
    set :rmq_url, rmq_url

    # report startup configuration
    RealSelf::logger.info("HTTP_LOG:        #{log_file}")
    RealSelf::logger.info("MONGO_HOST:      #{mongodb_host}")
    RealSelf::logger.info("MONGO_DATABASE:  #{mongodb_dbname}")
    RealSelf::logger.info("MONGO_POOL_SIZE: #{mongo_pool_size}")
    RealSelf::logger.info("RABBITMQ_URL     #{rmq_url.to_s}")
    RealSelf::logger.info("LOG_LEVEL:       #{RealSelf::logger.level}")

  end


  # basic health check
  # makes sure the mongodb is available
  get "/health" do
    mongo_ping = settings.mongo_db.command(:ping => 1).first
    mongo_ping[:ok] == 1.0 ? 202 : 500
  end


  # define routes
  get "/newsfeed/:type/:id" do
    args = unpack_params

    # reset the unread count if requested
    settings.newsfeed.reset_unread_count(args[:owenr]) if args[:mark_as_read]

    json(settings.newsfeed.get(
      args[:owner],
      args[:count],
      args[:before],
      args[:after],
      args[:query],
      args[:include_owner]))
  end


  get "/newsfeed/:type/:id/unread_count" do
    owner = RealSelf::Stream::Objekt.new(params[:type], params[:id])
    json(settings.newsfeed.get_unread_count(owner))
  end


  # RESTfully handle  and fan out an activity in the same way the daemon does
  # NOTE:  This route accepts only Activity payloads (not StreamActivity)
  # Requires that RABBITMQ_URL environment variable is set.
  post "/handle" do
    begin
      activity = RealSelf::Stream::Factory.from_json(
        RealSelf::ContentType::ACTIVITY,
        request.body.read)
    rescue JSON::Schema::ValidationError, MultiJson::ParseError => e
      invalid_argument_error(e.message)
    end

    result = handle_activity(activity)

    halt 500 if :ack != response
  end


  # server error
  error  do
    RealSelf::logger.error(env['sinatra.error'].message)
    RealSelf::logger.error(env['sinatra.error'].backtrace.join("\n"))

    [500, env['sinatra.error'].message]
  end


  # 404
  not_found do
    "These are not the droids you're looking for."
  end


  helpers do

    # handle the activity
    def handle_activity activity
      # create a publisher to handle the fanout
      publisher = RealSelf::Stream::Publisher.new({
        :heartbeat  => 60,
        :host       => settings.rmq_url.host,
        :password   => settings.rmq_url.password,
        :port       => settings.rmq_url.port,
        :user       => settings.rmq_url.user,
        :vhost      => '/'})

      # create the handler(s) for the posted activity type
      handlers = RealSelf::Handler::Factory.create(
        activity.prototype,
        RealSelf::ContentType::ACTIVITY,
        {mongo_db: settings.mongo_db, publisher: publisher} # handler constructor params
      )

      # wrap our calls to the handler(s) in the enclosure
      # to take advantage of our common error handling
      response = RealSelf::Feed::Enclosure.handle do
        handlers.each do |h|
          RealSelf::logger.info RealSelf.logger.info "#{h.class.name} handling #{activity.prototype}, UUID: #{activity.uuid}"
          h.handle activity
        end
      end

      # return an empty response on success
      :ack == response ? 202 : 500
    end


    # collect all of the request params, fill in defaults and validate
    #
    # @return [Hash]
    def unpack_params
      args                  = {}
      args[:owner]          = RealSelf::Stream::Objekt.new(params[:type], params[:id])
      args[:after]          = request[:after].to_s.strip.empty?        ?   nil    : request[:after].to_s.strip
      args[:before]         = request[:before].to_s.strip.empty?       ?   nil    : request[:before].to_s.strip
      args[:count]          = request[:count].to_s.strip.empty?        ?   nil    : request[:count].to_i.abs
      args[:include_owner]  = request[:include_owner].to_s.empty?      ?   false  : request[:include_owner].to_s == 'true'
      args[:interval]       = request[:interval].to_s.strip.empty?     ?   nil    : request[:interval].to_s.strip
      args[:mark_as_read]   = request[:mark_as_read].to_s.strip.empty? ?   false  : request[:mark_as_read].to_s.strip
      args[:query]          = {}

      # disallow specification of both 'after' and 'interval' in the same request
      unless args[:after].nil? or args[:interval].nil?
        invalid_argument_error("cannot specify both 'after' and 'interval' params")
      end

      # if an interval is specified, convert it to an appropriate
      # value for 'after'
      args[:after] = case args[:interval]
      when 'day'
        BSON::ObjectId.from_time(Time.now - 86400).to_s

      when 'week'
        BSON::ObjectId.from_time(Time.now - 86400 * 7).to_s

      when nil
        args[:count] ||= DEFAULT_FEED_PAGE_SIZE # use the default count if none specified
        args[:after]

      else
        invalid_argument_error('"interval" must be day | week')
      end

      # validate the requested count
      # if an interval has been specified, then don't limit the count
      if args[:interval].nil? and !args[:count].between?(1, MAX_STREAM_ITEM_COUNT)
        invalid_argument_error("1 <= count <= #{MAX_STREAM_ITEM_COUNT}")
      end

      args
    end
  end
end
