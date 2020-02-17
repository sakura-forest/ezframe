# frozen_string_literal: true

require 'minitest/autorun'
require 'lib/ezframe.rb'

require 'nokogiri'

class MaterializeTest < Minitest::Test
  include Ezframe

  def test_convert
    hthash = Ht.input(type: 'text', name: 'v1')
    res = Materialize.convert(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)
    assert_equal(2, doc.search('div').length)
  end

  def test_form
    hthash = Ht.form(child: [
      Ht.input(type: 'text', name: 'v1'),
      Ht.input(type: 'text', name: 'v2', dummy: 1)
    ])
    res = Materialize.form(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.search('form').length)
    assert_equal(2, doc.xpath("//div[contains(@class, 'input-field')]").length)
    assert_equal(1, doc.xpath("//input[@name='v1']").length)
    assert_equal(1, doc.xpath("//input[@dummy='1']").length)

    hthash = Ht.form(dummy: 1, child: [
      Ht.input(type: 'text', name: 'v1'),
      Ht.input(type: 'text', name: 'v2')
    ])
    res = Materialize.convert(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.xpath("//form[@dummy='1']").length)
  end

  def test_table
    hthash = Ht.table(tbdummy: 1, child: Ht.tr(trdummy: 1,  child: Ht.td(tddummy: 1, child: "inner")))
    res = Materialize.convert(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)
    assert_equal(1, doc.xpath("//table[@tbdummy=1]").length)
    assert_equal(1, doc.xpath("//tr[@trdummy=1]").length)
    assert_equal(1, doc.xpath("//td[@tddummy=1]").length)
  end

  def test_icon
    hthash = Ht.icon(dummy: 1, class: [ "red" ], name: "edit")
    res = Materialize.convert(hthash)
    assert_equal('i', res[:tag])
    assert_equal('edit', res[:child])
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)
    assert_equal(1, doc.xpath("//i[@dummy=1]").length)
    assert_equal(1, doc.xpath("//i[contains(@class, 'red')]").length)
  end

  def test_checkbox
    hthash = Ht.checkbox(name: "k1", value: 'v1', label: 'label1')
    res = Materialize.convert(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)
    assert_equal(1, doc.xpath("//label/input").length)
    assert_equal(1, doc.xpath("//label/span").length)
    assert_equal("v1", doc.xpath("//label/span/text()").text.strip)
  end

  def test_select
    hthash = Ht.select(label: "label1", name: "mytest", dummy: 1, item: [ ["k1", "v1"], ["k2", "v2"], ["k3", "v3", "default"] ])
    res = Materialize.convert(hthash)
    html = Html.convert(res)
    doc = Nokogiri::HTML(html)

    assert_equal(1, doc.xpath("//select[@dummy='1']").length)

    tmp = doc.xpath("//select/option[@value='k1']")
    assert_equal(1, tmp.length)
    assert_equal("v1", tmp.children[0].text.strip)
    tmp = doc.xpath("//select/option[@value='k3']")
    assert_equal(1, tmp.length)
    assert_equal("v3", tmp.children[0].text.strip)
    assert(tmp.attr("selected"))

    hthash = Ht.select(name: "mytest", item: { k1: "v1", k2: "v2", k3: ["v3", "default"] } )
    res = Materialize.convert(hthash)
    html = Html.convert(res)
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
