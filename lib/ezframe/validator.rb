module Ezframe
  # 入力フォームの値のバリデーションを行う
  class Validator
    # 与えるハッシュはカラムキーをキーとして、値は配列で以下の値
    #   0. 正規化で変更のあった場合はその値
    #   1. エラーがあった場合はエラーメッセージ
    def initialize(valid_h)
      @validate_h = valid_h
    end

    # １カラムに対してだけバリデーションを行う。
    def single_validation(target_key)
      EzLog.debug("single_validation: @validate_h=#{@validate_h}, target_key=#{target_key}")
      unless target_key
        raise "target_key is empty: #{@validate_h}"
        return []
      end
      cmd_a = []
      if @validate_h[target_key.to_sym]
        cmd_a = show_validate_result
      end
      if count_errors(@validate_h) == 0
        cmd_a.unshift({ reset_error: "#error-box-#{target_key}" })
      end
      comp_a = exec_completion(@form)
      cmd_a += comp_a if comp_a
      EzLog.debug("reset_error: #error-box-#{target_key}")
      EzLog.debug("single_validation: target_key=#{target_key}, @validate_h=#{@validate_h}, count=#{count_errors}, cmd_a=#{cmd_a}")
      return cmd_a
    end

    # 全てのカラムに対してバリデーションを行う
    # AJAXに送り返すコマンドの配列を返す
    def full_validation
      cmd_a = show_validate_result
      cmd_a.unshift({ reset_error: ".error-box" })
      EzLog.debug("full_validation: full, cmd_a=#{cmd_a}")
      return cmd_a
    end

    # フォームの値の有効性チェックし、ajax用返信ハッシュを生成
    def show_validate_result
      cmd_a = []
      @validate_h.each do |key, status|
        norm, err = status
        EzLog.debug("norm=#{norm}, err=#{err}")
        if norm
          cmd_a.push({ set_value: "input[name=#{key}]", value: norm })
        end
        if err
          msg = Message[err.to_sym] || err
          cmd_a.push({ set_error: "#error-box-#{key}", value: msg })
        end
      end
      return cmd_a
    end

    # validate_resultの中のエラーの数を数える
    def count_errors
      return @validate_h.count { |k, a| a[1] }
    end
  end
end
