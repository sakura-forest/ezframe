module Ezframe
  class Config
    class << self
      attr_accessor :value_h

      def load_files(dir)
        unless @value_h
          Dir["#{dir}/*.yml"].each do |file|
            load_one_file(file)
          end
        end
      end

      def load_one_file(filename)
        instr = File.open(filename, &:read)
        if instr.index("\#{")
          puts "use ENV: #{ENV['PG_USER']}"
          instr = Template.fill_in_text(instr)
          puts "instr=#{instr}"
        end
        begin
          yaml = YAML.load(instr)
        rescue
          mylog("YAML load error: #{filename}")
          return 
        end
        @value_h ||={}
        @value_h.update(yaml.recursively_symbolize_keys) if yaml.length>0
      end

      def [](k)
        @value_h[k] if @value_h
      end

      def []=(k, v)
        @value_h||={}
        @value_h[k]=v
      end

      def inspect
        @value_h.inspect
      end
    end
  end
end