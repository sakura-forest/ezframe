require_relative "sub_page_kit"

module Ezframe
  # 各顧客に関連づいた情報の編集を一般化したクラス
  class SubEditor < PageBase
    include EditorCommon

    def init_vars
      super
      @sort_key = :id
      # @parent_key = :customer
      # @use_detail_box = true
    end

    def get_parent_id
      params = @request.env["url_params"]
      unless params
        EzLog.info "[WARN] no url_params"
        return nil
      end
      return params[@parent_key.to_sym]
    end
  end
end
