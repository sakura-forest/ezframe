# frozen_string_literal: true
require_relative "single_page_kit"

module Ezframe
  class MainEditor < PageBase
    include EditorCommon
    include PageKit::Index
    include PageKit::Edit
    include PageKit::Detail

     def init_vars
      super
      @sort_key = :id
      @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area"}
    end   
  end
end
