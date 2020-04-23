module Ezframe
  class EzLog
    class << self
      @instance = nil

      def writer(level="", msg)
        unless @instance
          @instance = File.open("log/#{ENV['RACK_ENV']||'development'}.log", "a+")
          @instance.sync = true
        end
        @instance.puts "#{Time.now.to_s}:#{level.upcase}:#{msg}"
      end

      def level=(lv)
        @level = lv
      end

      def info(msg)
        writer("info", msg)  
      end

      def debug(msg)
        writer("debug", msg)
      end

      def warn(msg)
        writer("warn", msg)
      end

      def error(msg)
        writer("debug", msg)
      end

      def <<(msg)
        writer("", msg)
      end
    end
  end
end