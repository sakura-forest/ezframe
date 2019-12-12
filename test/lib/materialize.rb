# frozen_string_literal: true

require 'minitest/autorun'
require 'lib/ezframe.rb'

require 'nokogiri'

class MaterializeTest < Minitest::Test
  def test_convert
    hthash = { tag: 'input', type: 'text', key: 'v1' }
    res = Materialize.convert(hthash)
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)
    assert_equal(2, doc.search('div').length)
  end

  def test_form
    hthash = { tag: 'form', child: [
      { tag: 'input', type: 'text', key: 'v1' },
      { tag: 'input', type: 'text', key: 'v2', dummy: 1 }
    ] }
    res = Materialize.form(hthash)
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.search('form').length)
    assert_equal(2, doc.xpath("//div[contains(@class, 'input-field')]").length)
    assert_equal(1, doc.xpath("//input[@name='v1']").length)
    assert_equal(1, doc.xpath("//input[@dummy='1']").length)

    hthash = { tag: 'form', dummy: 1, child: [
      { tag: 'input', type: 'text', key: 'v1' },
      { tag: 'input', type: 'text', key: 'v2' }
    ] }
    res = Materialize.convert(hthash)
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.xpath("//form[@dummy='1']").length)
  end

  def test_table
    hthash = { tag: 'table', tbdummy: 1, child: { tag: 'tr', trdummy: 1,  child: { tag: 'td', tddummy: 1, child: "inner"} } }
    res = Materialize.convert(hthash)
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)
    assert_equal(1, doc.xpath("//table[@tbdummy=1]").length)
    assert_equal(1, doc.xpath("//tr[@trdummy=1]").length)
    assert_equal(1, doc.xpath("//td[@tddummy=1]").length)
  end

  def test_icon
    hthash = { tag: "icon", dummy: 1, class: [ "red" ], name: "edit" }
    res = Materialize.convert(hthash)
    assert_equal('i', res[:tag])
    assert_equal('edit', res[:child])
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)
    assert_equal(1, doc.xpath("//i[@dummy=1]").length)
    assert_equal(1, doc.xpath("//i[contains(@class, 'red')]").length)
  end

  def test_checkbox
    hthash = { tag: "checkbox", name: "k1", value: 'v1', label: 'label1' }
    res = Materialize.convert(hthash)
    assert_equal('label', res[0][:tag])
    assert_equal('k1', res[0][:for])

    assert_equal('input', res[1][:tag])
    assert_equal('k1', res[1][:name])
  end

  def test_select
    hthash = { tag: "select", label: "メニュー", name: "mytest", dummy: 1, items: [ ["k1", "v1"], ["k2", "v2"], ["k3", "v3", "default"] ] }
    res = Materialize.convert(hthash)
    html = Html.wrap(res)
    p html
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.xpath("//select[@dummy='1']").length)

    tmp = doc.xpath("//select/option[@value='k1']")
    assert_equal(1, tmp.length)
    assert_equal("v1", tmp.children[0].text.strip)
    tmp = doc.xpath("//select/option[@value='k3']")
    assert_equal(1, tmp.length)
    assert_equal("v3", tmp.children[0].text.strip)
    assert(tmp.attr("selected"))

    hthash = { tag: "select", name: "mytest", items: { k1: "v1", k2: "v2", k3: ["v3", "default"] } }
    res = Materialize.convert(hthash)
    html = Html.wrap(res)
    doc = Nokogiri::HTML(html)
    tmp = doc.xpath("//select/option[@value='k1']")
    assert_equal(1, tmp.length)
    assert_equal("v1", tmp.children[0].text.strip)
    tmp = doc.xpath("//select/option[@value='k3']")
    assert_equal(1, tmp.length)
    assert_equal("v3", tmp.children[0].text.strip)
    assert_equal(1, doc.xpath("//select/option[@selected='selected']").length)
  end

  def test_add_sibling
    assert_equal(%w[a b], Materialize.add_sibling("a", "b"))
    assert_equal(%w[a b], Materialize.add_sibling(["a"], "b"))
  end
end
