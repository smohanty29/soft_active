require 'logger'

module SoftActive
  class Config
    def self.logger
      @_logger ||= (defined?(::Rails) && ::Rails.logger) ? Rails.logger : 
        begin 
          logger = Logger.new(STDOUT)
          logger.progname = 'soft_active'
          logger
        end
    end
  end
end