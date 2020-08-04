# frozen_string_literal: true
require_relative "editor_common"
require_relative "page_maker"

module Ezframe
  # ページ遷移無しでデータを編集する仕組み
  class SinglePageEditor < PageBase
    include EditorCommon
    include PageMaker::Default
    include PageMaker::Index
    include PageMaker::Edit
    include PageMaker::Detail
    include PageMaker::Delete

    def init_var
      super
      @sort_key = :id
      @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area"}
      # @show_delete_button = nil
    end
  end
end
