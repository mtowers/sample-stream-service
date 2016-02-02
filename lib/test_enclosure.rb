module TestEnclosure
  def self.handle
    begin
      yield
      :ack

    rescue ArgumentError => ae
      RealSelf::logger.warn "Handler Warning - #{ae.message}"
      :requeue # requeue will NOT increment the retry count.  It just requeues the message.

    rescue StandardError => se
      RealSelf::logger.error "Handler Error - #{se.message}"
      :reject # increment the retry count and requeue for another attempt
    end
  end
end
