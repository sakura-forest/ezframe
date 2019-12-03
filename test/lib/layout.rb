# frozen_string_literal: true

require 'minitest/autorun'
require "lib/layout.rb"

require "nokogiri"

class MaterializeTest < Minitest::Test
  include EzView

  def test_child
    layout = Div.new(child: [ Input.new(type: "text") ])
    html = layout.to_html
    doc = Nokogiri::HTML(html)
    assert(1, doc.search("div").length)
    assert(1, doc.search("div input").length)

    layout = Div.new(child: [
      Input.new(type: "text", name: "k1", value: "testvalue", id: "first-input"),
      Input.new(type: "number", name: "k1", value: "testvalue", id: "second-input"),
      Select.new(name: "select1", id: "select1", items: [ 
        ["item1", "itemlabel1"], ["item2", "itemlabel2"] 
      ]),
      Select.new(name: "select2", id: "select2", items: { 
        item1: "itemlabel1", item2: "itemlabel2" 
      } )
    ])
    html = layout.to_html
    puts "html=#{html}"
    doc = Nokogiri::HTML(html)
    assert(2, doc.search("input").length)
    assert(1, doc.search("select").length)

    assert(1, doc.search("input#first-input").length)
    p "select", doc.search("select#select1")
    assert(1, doc.search("select#select1").length)

    p "option", doc.search("select#select1 option")
    assert_equal(2, doc.search("select#select1 option").length)
    assert_equal(2, doc.search("select#select2 option").length)
  end

  def test_to_hash
    layout = Div.new(id: "first-div", child: [
      Input.new(type: "text", name: "k1", value: "testvalue", id: "first-input"),
      Input.new(type: "number", name: "k1", value: "testvalue", id: "second-input"),
      Select.new(name: "select1", id: "select1", items: [ ["item1", "itemlabel1"], ["item2", "itemlabel2"] ])
    ])
    h = layout.to_hash
    assert(h.is_a?(Hash))
    assert_equal("div", h[:tag])
    assert(h[:child].is_a?(Array))
    assert("input", h[:child][0][:tag])
  end
end
