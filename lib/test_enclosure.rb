module TestEnclosure
  def self.handle
    begin
      yield
      :ack

    rescue ArgumentError => ae
      RealSelf::logger.warn "Handler Warning - #{ae.message}"
      :requeue

    rescue StandardError => se
      RealSelf::logger.error "Handler Error - #{se.message}"
      :reject
    end
  end
end
