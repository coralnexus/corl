
class Hiera
  module Coral_logger
    class << self
      def suitable?
        defined?(::Coral) == "constant"
      end

      def warn(message)
        ::Coral.logger.warn("hiera: #{message}")
      end

      def debug(message)
        ::Coral.logger.debug("hiera: #{message}")
      end
    end
  end
end