# frozen_string_literal: true
require_relative '../test_helper.rb'

class HtmlTest < GenericTest
  include Ezframe

  def test_convert
    html = Html.convert(tag: 'test_tag')
    assert(html.index('<test_tag>'), 'タグが生成される。')
    assert(html.index('</test_tag>'), 'タグが閉じられている。')

    html = Html.convert(tag: 'test_tag', child: Html.convert(tag: 'child_tag'))
    assert(html.index('<test_tag>'), '開始タグが生成される。')
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
    assert_equal('<input class="c1 c2 c3"/>', Html.convert(tag: 'input', class: %w[c1 c2 c3]))
    res = Html.convert(tag: 'div', class: 'c1', child: { tag: 'input', type: 'text', name: 'inp' })
    assert_equal('<div class="c1"><input type="text" name="inp"/></div>', res)
  end

  def test_textarea
    # value属性を使う
    h = { tag: "textarea", value: "1234\n567\n890\n"}
    res = Html.convert(h)
    assert_equal("<textarea>1234\n567\n890\n</textarea>", res)

    # child属性を使う
    h = { tag: "textarea", child: "1234\n567\n890\n"}
    res = Html.convert(h)
    assert_equal("<textarea>1234\n567\n890\n</textarea>", res)

    # value属性を使う
    html = Html.convert(Ht.textarea(value: "123\n456\n789\n"))
    assert_equal("<textarea>123\n456\n789\n</textarea>", html)

    # child属性を使う
    html = Html.convert(Ht.textarea(child: "123\n456\n789\n"))
    assert_equal("<textarea>123\n456\n789\n</textarea>", html)
  end
end
