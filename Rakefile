
require 'bunny'

desc 'Set up dead letter exchanges and queues'
task :dlx_initialize do
  amqp = ENV.fetch('RABBITMQ_URL', 'amqp://guest:guest@localhost:5672')

  puts "Setting up dead letter exchanges and queues..."
  puts "RabbitMQ:  #{amqp}"

  queues = ['ACTIVITY_QUEUE', 'STREAM_ACTIVITY_QUEUE', 'DIGEST_QUEUE'].map do |var|
    ENV[var]
  end.uniq.compact

  if queues.empty?
    puts "No queues specified."
    puts "Usage:"
    puts ""
    puts "RABBITMQ_URL=[amqp://[user]:[password]@[host]:[port]] [QUEUE_TYPE]=[your queue name] bundle exec rake dlx_initialize"
    puts ""
    puts "supported queue types:  ACTIVITY_QUEUE, STREAM_ACTIVITY_QUEUE, DIGEST_QUEUE"

  else
    puts "Queues:  #{queues.to_s}"

    puts "Connecting to RabbitMQ..."
    conn = Bunny.new(amqp)
    conn.start

    puts "Creating channel..."
    ch  = conn.create_channel

    queues.each do |name|
      x = create_dlx(ch, name)
      create_dlq(ch, x, name)
    end

    conn.close

    puts "Done!"
  end
end

def create_dlx(channel, queue_name)
  puts "Creating DLX for queue:  #{queue_name}"
  channel.direct("dlx.#{queue_name}")
end

def create_dlq(channel, exchange, queue_name)
  puts "Creating DLQ for queue: #{queue_name}"
  channel.queue("dlq.#{queue_name}", :auto_delete => false, :durable => true).bind(exchange, :routing_key => "#")
end

