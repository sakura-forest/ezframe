# frozen_string_literal: true
require_relative "page_maker"

module Ezframe
  class MainEditor < PageBase
    include Ezframe
    include EditorCommon
    include PageMaker::Default
    # include PageMaker::Index
    include PageMaker::Edit
    include PageMaker::Detail

    def init_var
      super
      @sort_key = :id
      # @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area" }
      @dom_id = { create: "main-content", edit: "main-content", index: "main-content", detail: "main-content" }
    end   
  end
end
