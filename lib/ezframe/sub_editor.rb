# frozen_string_literal: true
require_relative "page_maker"

module Ezframe
  # 各顧客に関連づいた情報の編集を一般化したクラス
  class SubEditor < PageBase
    include Ezframe
    include EditorCommon
    include PageMaker::Default
    include PageMaker::Edit
    include PageMaker::Detail

    def init_var
      super
      @sort_key = :id
      #tab_id = "##{@class_snake}_tab"
      #@dom_id = { create: tab_id, edit: tab_id, index: tab_id, detail: tab_id }
      # @parent_key = :customer
      # @use_detail_box = true
    end

    def public_default_post
      @id = get_id
      return show_index
    end

    def show_index
      EzLog.debug("#{@class_snake}: show_index")
      data_a = list_for_index
      list = Ht::List.new
      data_a.each do |data|
        @column_set.set_values(data)
        list.add_raw(show_index_item)
      end
      # return { inject: "##{@class_snake}-tab", body: list.to_ht }
      return { inject: "##{@class_snake}-tab", body: Html.convert(Ht.compact([".container > .row", [ list.to_ht ]])) }
    end
  end
end
