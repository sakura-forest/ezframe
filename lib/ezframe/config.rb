module Ezframe
  class Config
    class << self
      attr_accessor :value_h

      def load_files(dir)
        Dir["#{dir}/*.yml"].each do |file|
          load_one_file(file)
        end
      end

      def load_one_file(filename)
        begin
          yaml = YAML.load_file(filename)
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
    end
  end
end