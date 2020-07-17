# frozen_string_literal: true
require_relative "page_maker"

module Ezframe
  # 各顧客に関連づいた情報の編集を一般化したクラス
  class SubEditor < PageBase
    include EditorCommon
    include PageMaker::Index
    include PageMaker::Edit
    include PageMaker::Detail

    def init_vars
      super
      @sort_key = :id
      tab_id = "##{@class_snake}_tab"
      @dom_id = { create: tab_id, edit: tab_id, index: tab_id, detail: tab_id }
      # @parent_key = :customer
      # @use_detail_box = true
    end
  end
end
