# frozen_string_literal: true
require_relative '../test_helper.rb'

class HtmlTest < GenericTest
  include Ezframe

  def test_convert
    html = Html.convert(tag: 'test_tag', wrap: true)
    assert(html.index('<test_tag>'), 'タグが生成される。')
    assert(html.index('</test_tag>'), 'タグが閉じられている。')

    html = Html.convert(tag: 'test_tag', wrap: true, child: Html.convert(tag: 'child_tag', wrap: true))
    assert(html.index('<test_tag>'), '開始タグが生成される。')
    assert(html.index('<child_tag'), '子が含まれる。')

    html = Html.convert(Ht.input(type: 'text'))
    assert(html.index('input '))
    assert(html.index('type="text"'))

    html = Html.convert(Ht.div(class: 'class1', id: 'myid1', child: Ht.div(class: 'class2')))

    assert(html.index('<div class="class1"'))
    assert(html.index('<div class="class2"'))
    assert(html.index('</div>'))
  end

  def test_hthash
    assert_equal('<input class="c1 c2 c3"/>', Html.convert(Ht.input(class: %w[c1 c2 c3])))
    res = Html.convert(Ht.div(class: 'c1', child: Ht.input(type: 'text', name: 'inp')))
    assert_equal('<div class="c1"><input type="text" name="inp"/></div>', res)
  end

  def test_textarea
    # value属性を使う
    h = Ht.textarea(value: "1234\n567\n890\n")
    res = Html.convert(h)
    assert_equal("<textarea>1234\n567\n890\n</textarea>", res)

    # child属性を使う
    h = Ht.textarea(child: "1234\n567\n890\n")
    res = Html.convert(h)
    assert_equal("<textarea>1234\n567\n890\n</textarea>", res)

    # value属性を使う
    html = Html.convert(Ht.textarea(value: "123\n456\n789\n"))
    assert_equal("<textarea>123\n456\n789\n</textarea>", html)

    # child属性を使う
    html = Html.convert(Ht.textarea(child: "123\n456\n789\n"))
    assert_equal("<textarea>123\n456\n789\n</textarea>", html)
  end

  def test_before_after_attr
    h = Ht.div(before: "before_elem", child: "main_elem", after: "after_elem")
    res = Html.convert(h)
    assert_equal("before_elem<div>main_elem</div>after_elem", res)

    h = Ht.div(before: Ht.div("before_elem"), child: "main_elem", after: Ht.div("after_elem"))
    res = Html.convert(h)
    assert_equal("<div>before_elem</div><div>main_elem</div><div>after_elem</div>", res)
  end

  def test_ht_list
    p Html.convert(Ht::Ul.new(%w[a b c d]).to_h)
  end
end
