
# Simple fanout example
#
# Listens for Activity messages, looks up users in the follow graph
# that are following one or more components of the activity
# and issues a fanned out stream activity for each user
class FanoutHandler
  include RealSelf::Handler::Activity


  def initialize mongo_db:, publisher:
    @mongo_db   = mongo_db
    @publisher  = publisher

    RealSelf::Graph::Follow.configure @mongo_db
  end


  def handle activity
    RealSelf::logger.info "Processing activity:  #{activity.to_s}"

    # build an array of the objects in the activity
    objects = []
    objects << activity.actor
    objects << activity.object
    objects << activity.target
    activity.extensions.each_value { |obj| objects << obj}
    objects.compact!

    # retrieve the follow map from the follow graph and
    # publish fanned out stream activities for each follower
    RealSelf::Graph::Follow.followers_of(:user, objects) do |follower, following|
      stream_activity = RealSelf::Stream::StreamActivity.new follower, activity, following

      RealSelf::logger.info "Fanning out activity #{activity.uuid} to #{follower.to_s}"

      @publisher.publish(
        stream_activity,
        stream_activity.prototype,
        RealSelf::ContentType::STREAM_ACTIVITY)
    end
  end


  # regsiter for all activity types that should be fanned out to followers
  register_handler 'user.publish.comment'
  register_handler 'user.upload.photo'
  register_handler 'user.upload.video'
end
