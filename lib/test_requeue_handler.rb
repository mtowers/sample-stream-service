class TestRequeueHandler
  include RealSelf::Handler::StreamActivity

  def initialize debug_mode:
    @debug_mode = debug_mode
  end


  def handle stream_activity
    RealSelf::logger.info "[#{Time.now}] HANDLER HANDLING: #{stream_activity}"
    raise ArgumentError, "[#{Time.now}] REQUEUEING: #{stream_activity}"
  end


  register_handler 'test.requeue.stream_activity'
end
