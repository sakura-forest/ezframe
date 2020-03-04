# frozen_string_literal: true
require_relative '../test_helper.rb'

class HtmlTest < GenericTest
  include Ezframe

  def test_convert
    html = Html.convert(tag: 'test_tag')
    assert(html.index('<test_tag'), 'タグが生成される。')
    assert(html.index('/>'), 'タグが閉じられている。')

    html = Html.convert(tag: 'test_tag', child: Html.convert(tag: 'child_tag'))
    assert(html.index('<test_tag '), '開始タグが生成される。')
    assert(html.index('<child_tag'), '子が含まれる。')

    html = Html.convert(tag: 'input', type: 'text')
    assert(html.index('input '))
    assert(html.index('type="text"'))

    html = Html.convert(tag: 'div', class: 'class1', id: 'myid1', child: { tag: 'div', class: 'class2' })

    assert(html.index('<div class="class1"'))
    assert(html.index('<div class="class2"'))
    assert(html.index('</div>'))
  end

  def test_hthash
    assert_equal('<input class="c1 c2 c3" />', Html.convert(tag: 'input', class: %w[c1 c2 c3]))
    res = Html.convert(tag: 'div', class: 'c1', child: { tag: 'input', type: 'text', name: 'inp' })
    assert_equal('<div class="c1"><input type="text" name="inp" /></div>', res)
  end

  def test_textarea
    h = { tag: "textarea", value: "1234\n567\n890\n"}
    res = Html.convert(h)
    assert_equal("<textarea >1234<br>567<br>890<br></textarea>", res)
  end
end
