class TestRejectHandler
  include RealSelf::Handler::StreamActivity

  def initialize(debug_mode:)
    @debug_mode = debug_mode
  end


  def handle stream_activity
    RealSelf::logger.info "[#{Time.now}] HANDLER HANDLING: #{stream_activity}"
    raise StandardError, "[#{Time.now}] REJECTING: #{stream_activity}"
  end


  register_handler 'test.reject.stream_activity'
end
