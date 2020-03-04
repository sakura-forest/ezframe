require_relative "../test_helper.rb"

class TemplateTest < GenericTest
  def test_fill_template
    test_file = '/tmp/template_test.html'
    File.open(test_file, 'w') do |f|
      f.print "abcd\n\#{var}\nfghij"
    end
    res = Template.fill_from_file(test_file, var: 'new')
    assert_equal("abcd\nnew\nfghij", res)
  end
end
