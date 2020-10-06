module Ezframe
  module PageMaker
    class PageContent
      attr_accessor :body, :title, :url

      def to_ht
        return @body.respond_to?(:to_ht) ? @body.to_ht : @body
      end
    end

    class IndexPageMaker
      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
      end

      # 一覧表の生成
      def make_content
        # 表示データの取得
        list = @parent.list_for_index

        # 一覧表示カラムの決定
        target_keys = @parent.index_keys || @parent.column_set.index_keys || @parent.column_set.view_keys

        # テーブル生成
        table = Ht::Table.new(wrap_tag: Ht.compact("table.table.table-bordered.dataTable"))

        # 項目名欄の生成
        labels = @table_labels
        unless labels
          labels = target_keys.map do |k| 
            column = @parent.column_set[k]
            if column
              column.label(force: true) || "　"
            else
              EzLog.error("IndexPageMaker.make_content: no column defined: #{k}")
              "　"
            end
          end
        end
        table.header = labels

        list.each do |data|
          @parent.column_set.clear
          @parent.column_set.values = data
          table.add_item(@parent.column_set.view_array(target_keys), row_attr: { ezevent: "on=click:url=#{@parent.make_base_url(data[:id])}/detail" })
        end
        table.add_before(Ht.compact([ "button.btn.btn-primary#create-btn:ezevent=[on=click:url=#{@parent.make_base_url}/create]", [ "i.fa.fa-plus", "text:#{Message[:create_button_label]}" ] ]))

        content = PageContent.new
        content.body = table_ht = table.to_ht
        elem = Ht.search(table_ht, "table")
        elem[:ezload] = "command=enable_datatable"
        content.title = Message[:index_page_title]
        return content
      end
    end

    class EditPageMaker
      include EditorCommon

      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
        @response = @controller.response
        @ezevent = @controller.ezevent
      end

      # 新規登録フォームの表示
      def show_create_form
        content = make_edit_form(:create)
        content.title = "新規登録"
        return content
      end

      # 編集フォームの表示
      def show_edit_form
        @id ||= @parent.id
        return show_message_page("no id", "id is not defined") unless @id
        data = @parent.column_set.set_from_db(@id)
        return show_message_page("no data", "data is not defined: #{@id}") unless data
        content = make_edit_form(:edit)
        content.title = "情報編集: #{data[:m_name]}, #{data[:f_name]}"
        return content
      end


      # 編集フォームの生成
      def make_edit_form(typ = :edit)
        target_keys = @parent.column_set.edit_keys
        new_form = Bootstrap::Form.new
        new_form.action = "#{@parent.make_base_url}/#{typ}"
        target_keys.map { |key| make_edit_line(new_form, key) }
        cancel_button = make_cancel_button("on=click:url=#{@parent.make_base_url(@id)}/#{typ}:cancel=true:with=form")
        send_button = edit_finish_button(typ)
        new_form.append = Ht.compact("div", [send_button, cancel_button])
        content = PageContent.new
        content.body = new_form
        return content
      end

      # 編集ページの行を生成
      def make_edit_line(form, key)
        column = @parent.column_set[key.to_sym]
        unless column
          EzLog.error("undefined column entry: #{key}")
          return nil
        end
        inpgrp = form.add_input(column.form)
        return nil unless inpgrp
        inpgrp.add_prepend(column.label)
        return inpgrp
      end

      # 編集完了ボタン
      def edit_finish_button(typ = :edit, event = nil)
        msg = Message["#{typ}_finish_button_label"]
        event ||= "on=click:url=#{@parent.make_base_url(@id)}/#{typ}:with=form"
        return Ht.compact("button.btn.btn-primary#edit-finish-button:ezevent=[#{event}]", [ "i.fa.fa-check", "span:#{msg}" ])
      end
    end

    class DetailPageMaker
      def initialize(parent)
        @parent = parent
        @controller = @parent.controller
      end

      def make_content
        target_keys = @detail_keys || @parent.column_set.view_keys
        list = Ht::List.new
        target_keys.each do |key|
          column = @parent.column_set[key]
          row = make_detail_line(column)
          list.add_item(row) if row
        end
        list.add_item(button_for_detail_box)
        content = PageContent.new
        content.body = list
        return content
      end

      # 詳細表示欄の一行を生成
      def make_detail_line(column)
        view = column.view
        if view
          if view.strip.index("\n")
            view = Ht.pre(view) 
          else
            view = Ht.span(view)
          end
          return Ht.compact("p", [ "small.text-secondary:#{column.label}", view ])
        end
        return nil
      end

      def button_for_detail_box # (data)
        # buttons = Ht.compact("button.btn.btn-primary:ezevent=[on=click:url=#{make_base_url(data[:id])}/edit]", [ "i.fas.fa-edit", "span:#{Message[:edit_button_label]}" ])
        buttons = Ht.compact("button.btn.btn-primary:ezevent=[on=click:url=#{@parent.make_base_url(@parent.id)}/edit]", [ "i.fas.fa-edit", "span:#{Message[:edit_button_label]}" ])
        buttons += make_delete_button if @show_delete_button
        return Ht.compact(".button-box", buttons)
      end
    end


  end
end
