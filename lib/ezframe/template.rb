# frozen_string_literal: true

module Ezframe
  class Template
    class << self
      def fill_from_file(filename, opts = {})
        dir = File.dirname(filename)
        unless File.exist?(filename)
          raise "fill_template: file does not exist: #{filename}"
        end
        instr = File.open(filename, &:read)
        return fill_in_text(instr, opts)
      end

      def fill_in_text(text, opts = {})
        outstr = text.gsub(/\#\{([^\}]+)\}/) do
          keyword = $1
          if opts[keyword.to_sym]
            opts[keyword.to_sym] 
          elsif ENV[keyword]
            ENV[keyword]
          else
            EzLog.info "[WARN] no value for keyword: #{keyword}"
            nil
          end
        end
        return outstr
      end
    end
  end
end
