# frozen_string_literal: true
require_relative "main_page_kit"

module Ezframe
  class MainEditor < PageBase
    include EditorCommon
    include MainPageKit::Default
    include MainPageKit::Index
    include MainPageKit::Edit
    include MainPageKit::Detail

     def init_vars
      super
      @sort_key = :id
      @event = @parsed_body[:ezevent] if @parsed_body
      @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area"}
    end   
  end
end
