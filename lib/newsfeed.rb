# Simple newsfeed feed handler
#
# Listens for StreamActivity messages with the registered prototype (routing key)
# and inserts an entry into the newsfeed for each stream activity owner
class Newsfeed < RealSelf::Feed::Permanent
  FEED_NAME = :newsfeed.freeze

  include RealSelf::Handler::StreamActivity
  include RealSelf::Feed::UnreadCountable


  def initialize debug_mode:, mongo_db:
    @mongo_db = mongo_db
  end


  def handle stream_activity
    owner = stream_activity.owner

    RealSelf::logger.info "Inserting into newsfeed.  Owner: #{owner.to_s}, Prototype: #{stream_activity.prototype}, UUID: #{stream_activity.uuid}"

    insert owner, stream_activity  # insert the activity into the feed collection
    increment_unread_count owner   # increment the unread count for the newsfeed
  end


  # register the activity types that should be included in the newsfeed
  register_handler 'user.publish.comment'
  register_handler 'user.upload.photo'
  register_handler 'user.upload.video'
end
