
class Hiera
  module Corl_logger
    class << self
      def suitable?
        defined?(::CORL) == "constant"
      end

      def warn(message)
        ::CORL.logger.warn("hiera: #{message}")
      end

      def debug(message)
        ::CORL.logger.debug("hiera: #{message}")
      end
    end
  end
end