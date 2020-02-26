module Ezframe
  class Jquery
    class << self
      def into_html_header
        css_a = Config[:extra_css_list].map {|file| "<link href=\"#{file}\" rel=\"stylesheet\">\n" }
        js_a = Config[:extra_js_list].map {|file| "<script src=\"#{file}\"></script>\n" }

        css_files = Dir["./asset/css/*.css"]||[]
        css_a += css_files.map do |file|
          file.gsub!("./asset", "")
          "<link href=\"#{file}\" rel=\"stylesheet\">\n"
        end
        js_files = Dir["./asset/js/*.js"]||[]
        js_a += js_files.map do |file|
          file.gsub!("./asset", "")
          "<script src=\"#{file}\"></script>\n"
        end
        (css_a+js_a).join
      end

      def into_bottom_of_body
        ""
      end

      def convert(ht_h)
      end
    end
  end
end