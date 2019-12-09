# frozen_string_literal: true

module EzView
  class Template
    def self.embed_words(keyword, dir, opts)
      return opts[keyword.to_sym] if opts[keyword.to_sym]

     temp = "#{dir}/#{keyword}.html"
     return File.open(temp, &:read) if File.exist?(temp)
    end

    def self.fill_template(filename, opts = {})
      dir = File.dirname(filename)
      unless File.exist?(filename)
        raise "fill_template: file does not exist: #{filename}"
      end

      instr = File.open(filename, &:read)
      outstr = instr.gsub(/\#\{(.*)\}/) do
        embed_words(Regexp.last_match(1), dir, opts)
      end
      outstr
    end
  end
end
