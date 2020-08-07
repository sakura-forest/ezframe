module Ezframe
  class EzLog
    class << self
      attr_accessor :log_file

      def open_log_file
        unless @log_file
          file = "log/#{ENV['RACK_ENV']||'development'}.log"
          @log_file = ::Logger.new(file)
        end
        return @log_file
      end

      def writer(level="", msg)
        unless @log_file
          open_log_file 
        end
        @log_file << msg
      end

      def level=(lv)
        @level = lv
      end

      def info(msg)
        @log_file.info(msg)
      end

      def debug(msg)
        @log_file.debug(msg)
      end

      def warn(msg)
        @log_file.debug(msg)
      end

      def error(msg)
        @log_file.error(msg)
      end

      def <<(msg)
        # writer("", msg)
      end
    end
  end
end