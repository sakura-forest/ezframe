module Ezframe
  class Message
    class << self
      def init
        load_yaml_files
      end

      def load_yaml_files(dir = "./message")
        unless @catalog
          @catalog = {}
          Dir["#{dir}/*.yml"].each do |file|
            # p file
            load_one_file(file)
          end
        end
        # puts "catelog=#{@catalog}"
      end

      def load_one_file(file)
        begin
          yaml = YAML.load_file(file)
          p yaml
        rescue
          mylog("YAML load error: #{file}")
          return 
        end
        if /([a-z]{2})\.yml$/ =~ file
          lang = $1
          @catalog[lang.to_sym] = yaml.recursively_symbolize_keys
        end
      end

      def languages
        return @catalog.keys
      end

      def get(key, lang = nil)
        lang = languages[0] unless lang
        messages = @catalog[lang]
        return messages[key.to_sym] if messages
        return nil
      end

      def [](key)
        return get(key)
      end
    end
  end
end