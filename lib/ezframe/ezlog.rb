module Ezframe
  class EzLog
    class << self
      attr_accessor :log_file

      def open_log_file
        unless @log_file
          file = "log/#{ENV['RACK_ENV']||'development'}.log"
          @log_file = ::Logger.new(file)
#          $stderr.puts "open_log_file: #{file}"
#          @log_file = File.open(file, "a+")
#          @log_file.sync = true
        end
        return @log_file
      end

      def writer(level="", msg)
        unless @log_file
          open_log_file 
        end
        @log_file << msg
#        $stderr.puts "writer: #{msg}"
#        @log_file.puts "#{Time.now.to_s}:#{level.upcase}:#{msg}"
      end

      def level=(lv)
        @level = lv
      end

      def info(msg)
        @log_file.info(msg)
#         writer("info", msg)  
      end

      def debug(msg)
        @log_file.debug(msg)
#         writer("debug", msg)
      end

      def warn(msg)
        @log_file.debug(msg)
#        writer("warn", msg)
      end

      def error(msg)
        @log_file.error(msg)
        # writer("debug", msg)
      end

      def <<(msg)
        # writer("", msg)
      end
    end
  end
end