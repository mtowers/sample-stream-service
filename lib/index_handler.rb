# Simple search terms feed handler
#
# Listens for StreamActivity messages with the registered prototype (routing key)
# and inserts an entry into the search_terms index to facilitate retrieval
class IndexHandler

  include RealSelf::Handler::Activity

  def initialize elasticsearch_client:
    @es_client = elasticsearch_client
  end

  # insert the activity into an index/type in the cluster
  def index activity
    default_fields     = {
                          "user_id"       => activity.actor.id,
                          "action"        => activity.verb
                          "indexed_date"  => Time.new.strftime("%Y-%m-%dT%H:%M:%S")
                         }
    extended_fields    = activity.extensions || {}
    @es_client.index index:'stream-sample',
                     type: activity.object,
                     body: default_fields.merge extended_fields
  end

  def handle activity
    RealSelf::logger.info "Indexing item for discovery.  Owner: #{activity.owner.to_s}, Prototype: #{activity.prototype}, UUID: #{activity.uuid}"
    index activity
  end

  # register the activity types that should be indexed for search
  register_handler 'user.publish.review'
  register_handler 'user.publish.comment'
end
