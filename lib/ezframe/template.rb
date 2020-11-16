# frozen_string_literal: true

module Ezframe
  class Template
    class << self
      def fill_from_file(filename, opts = {})
        dir = File.dirname(filename)
        unless File.exist?(filename)
          raise "fill_template: file does not exist: #{filename}"
        end
        instr = File.read(filename)
        instr = fill_in_file(instr, dir, opts)
        return fill_in_text(instr, opts)
      end

      def fill_in_file(text, dir, opts = {})
        outstr = text.gsub(/:@([\w\-]+\.[\w\-]+)@:/) do
          keyword = $1
          if keyword.index(".")
            fname = "#{dir}/#{keyword}"
            File.read(fname) if File.exist?(fname)
          end
        end
        return outstr
      end

      def fill_in_text(text, opts = {})
        outstr = text.gsub(/:@(\w+)@:/) do
          keyword = $1
          if opts[keyword.to_sym]
            val = opts[keyword.to_sym]
            val = Html.convert(val) unless val.is_a?(String)
            val
          elsif ENV[keyword]
            ENV[keyword]
          else
            EzLog.info "[WARN] no value for keyword: #{keyword}"
            ""
          end
        end
        return outstr
      end
    end
  end
end
