require 'minitest/autorun'
require 'lib/template.rb'

class TemplateTest < Minitest::Test
  def test_fill_template
    test_file = '/tmp/template_test.html'
    File.open(test_file, 'w') do |f|
      f.print "abcd\n\#{var}\nfghij"
    end
    res = Filta::Template.fill_template(test_file, var: 'new')
    assert_equal('abcd\nnew\nfghij', res)
  end
end
