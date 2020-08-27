module Ezframe
  class Config
    class << self
      attr_accessor :value_h

      def init(dir = "./config")
        load_files(dir)
      end

      def load_files(dir)
        unless @value_h
          load_dir(dir)
          rack_env = ENV['RACK_ENV']
          env_dir = "#{dir}/#{rack_env}"
          if rack_env && File.directory?(env_dir)
            load_dir(env_dir)
          end
        end
      end

      def load_dir(dir)
        Dir["#{dir}/*.yml"].each do |file|
          load_one_file(file)
        end
      end

      def load_one_file(filename)
        instr = File.open(filename, &:read)
        if instr.index("\#{")
          instr = Template.fill_in_text(instr)
        end
        begin
          yaml = YAML.load(instr, symbolize_names: true)
        rescue => e
          EzLog.info("YAML load error: #{filename}:#{e}")
          return 
        end
        @value_h ||={}
        @value_h.update(yaml) if yaml.length>0
      end

      def [](k)
        @value_h[k] if @value_h
      end

      def []=(k, v)
        @value_h||={}
        @value_h[k]=v
      end

      def delete(k)
        @value_h.delete(k) if @value_h[k]
      end

      def inspect
        @value_h.inspect
      end
    end
  end
end