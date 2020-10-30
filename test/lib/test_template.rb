require_relative "../test_helper.rb"

class TemplateTest < GenericTest
  def test_fill
    test_file = '/tmp/template_test.html'
    File.open(test_file, 'w') do |f|
      f.print "abcd\n\:@var@:\nfghij"
    end
    res = Template.fill_from_file(test_file, var: 'new')
    assert_equal("abcd\nnew\nfghij", res)
  end

  def test_fill_include_file
    test_file = '/tmp/template_test.html'
    File.open(test_file, 'w') do |f|
      f.print "abcd\n\:@var@:file=:@template_include.html@:\nfghij"
    end
    include_file = '/tmp/template_include.html'
    File.open(include_file, 'w') do |f|
      f.print "include_file_contents"
    end
    res = Template.fill_from_file(test_file, var: 'new')
    assert_equal("abcd\nnewfile=include_file_contents\nfghij", res)
  end
end
