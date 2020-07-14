require_relative "editor_common"
require_relative "single_page_kit"

module Ezframe
  # ページ遷移無しでデータを編集する仕組み
  class SinglePageEditor < PageBase
    include EditorCommon
    include PageKit::Default
    include PageKit::Index
    include PageKit::Edit
    include PageKit::Detail
    include PageKit::Delete

    def init_vars
      super
      @sort_key = :id
      @dom_id = { create: "create-area", edit: "edit-area", index: "index-area", detail: "detail-area"}
      # @show_delete_button = nil
    end
  end
end
