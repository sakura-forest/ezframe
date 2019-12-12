# frozen_string_literal: true

require 'minitest/autorun'
require 'lib/html.rb'
require 'nokogiri'

class HtmlTest < Minitest::Test
  def test_wrap
    html = Html.wrap(tag: 'test_tag')
    assert(html.index('<test_tag'), 'タグが生成される。')
    assert(html.index('/>'), 'タグが閉じられている。')

    html = Html.wrap(tag: 'test_tag', child: Html.wrap(tag: 'child_tag'))
    assert(html.index('<test_tag '), '開始タグが生成される。')
    assert(html.index('<child_tag'), '子が含まれる。')

    html = Html.wrap(tag: 'input', type: 'text')
    assert(html.index('input '))
    assert(html.index('type="text"'))

    html = Html.wrap(tag: 'div', class: 'class1', id: 'myid1', child: { tag: 'div', class: 'class2' })

    assert(html.index('<div class="class1"'))
    assert(html.index('<div class="class2"'))
    assert(html.index('</div>'))
  end

  def test_hthash
    assert_equal('<input class="c1 c2 c3"/>', Html.wrap(tag: 'input', class: %w[c1 c2 c3]))
    res = Html.wrap(tag: 'div', class: 'c1', child: { tag: 'input', type: 'text', name: 'inp' })
    assert_equal('<div class="c1">
<input type="text" name="inp"/>
</div>
', res)
  end

  def test_table
    matrix = [ %w[a b], %w[c d] ]
    matrix[0][0] = { tag: "icon", name: "edit", dummy: 1 }
    hthash = Html::Table.new(matrix).to_hthash
    html = Html.wrap(hthash)
    doc = Nokogiri::HTML(html)
    tmp = doc.xpath("//td")
    assert_equal(4, tmp.length)
    tmp = doc.xpath("//tr")
    assert_equal(2, tmp.length)
    tmp = doc.xpath("//icon")
    assert_equal(1, tmp.length)
    assert(tmp.attr("dummy"))
  end
end
