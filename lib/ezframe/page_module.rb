module Ezframe
  module PageMaker
    module Default
      def public_default
        @id ||= get_id
        if @id
          # idがあったら、詳細表示
          public_detail
          return
        end
        # 一覧表示
        public_index
      end

      # 一覧表示
      def public_index
        @index_page_maker ||= IndexPageMaker
        maker = @index_page_maker.new(self)
        content = maker.make_content
        if @request.xhr?
          EzLog.debug("public_index: response=#{@response}")
          @response.command  = { command: "inject", target: @target_box || "#main-content" }
          @response.body = content
          if @set_history
            @response.set_url = @request.path_info
            @response.title = "データ一覧"
          end
        else
          layout = Layout.new
          layout.embed[:body] = content.body
          @response.body = layout
        end
      end

      # 一覧ページ用のデータリスト生成
      def list_for_index(where = nil)
        where ||= {}
        where.update(deleted_at: nil)
        return @column_set.dataset.where(where).order(@sort_key).all
      end
    end

    module Edit
      # 新規データ登録
      def public_create
        @typ ||= :create
        content = branch(@typ)
        return unless content
        if @request.xhr?
          @response.body = content
          @response.command = { command: "inject", target: @target_box || "#main-content" }
          if @set_history
            @response.set_url = @request.path_info
            @response.title = content.title if content.respond_to?(:title)
          end
        else
          layout = Layout.new
          layout.embed[:main_content] = content.body
          layout.embed[:page_title] = content.title
          @response.body = layout
        end
      end

      # 顧客データ編集
      def public_edit
        @typ = :edit
        public_create
      end

      def branch(typ = :edit)
        if typ == :edit
          @id ||= get_id
          raise "no id for edit page" unless @id
        end
        @ezevent = @controller.ezevent
        # EzLog.debug("Edit.branch: ezevent: #{@ezevent}")
        @edit_page_maker ||= EditPageMaker
        if @ezevent[:branch] == "single_validate"
          EzLog.debug("Edit.branch: single_validate")
          # validation = Validator.new(@parent.column_set.validate(@controller.event_form))
          validation = Validator.new(@column_set.validate(@controller.event_form))
          @response.command = validation.validate_one(@ezevent[:target_key])
          return nil
        elsif @ezevent[:cancel]
          @response.command = { command: "redirect", target: "#{make_base_url}/#{@id}" }
          return nil
        end

        maker = @edit_page_maker.new(self)
        EzLog.debug("event_form=#{@controller.event_form}")
        event_form = @controller.event_form
        if event_form
          EzLog.debug("Edit.branch: store edit values")
          # 入力後。フォーム内容をDBに格納
          validation = Validator.new(@column_set.validate(event_form))
          if validation.count_errors > 0
            cmd_a = validation.validate_all
            EzLog.debug("validate_all: #{cmd_a}")
            @response.command = cmd_a
            return nil
          end
          if typ == :create
            @id = store_create_form
          else
            store_edit_form
          end
          act_after_edit
          return nil
        else
          EzLog.debug("Edit.branch: show_form")
          # 入力前。フォームを表示
          if typ == :create
            content = maker.show_create_form
            raise if content.is_a?(String)
          else
            content = maker.show_edit_form
            raise if content.is_a?(String)
          end
          return content
        end
      end

      # フォームをDBに格納
      def store_edit_form
        @id ||= get_id
        @column_set.update(@id, @ezevent[:form])
      end

      def store_create_form
        values = {}
        values.update(@ezevent[:form])
        values.update(@controller.route_params)
        EzLog.debug("store_create_form: #{values}")
        @column_set[:id].value = @id = @column_set.create(values)
        return @id
      end

      def act_after_edit
        public_detail
      end
    end

    # 詳細表示ページ生成キット
    module Detail
      # データ詳細表示
      def public_detail
        @id ||= get_id
        @detail_page_maker ||= DetailPageMaker
        maker = @detail_page_maker.new(self)
        @column_set.set_from_db(@id)
        content = maker.make_content
        if @request.xhr?
          @response.command = { command: "inject", target: @target_box || "#main-content" }
          @response.body = content
          if @set_history
            @response.set_url = make_base_url
            @response.title =  "詳細情報"
          end
          # EzLog.debug("public_detail.AJAX: #{@response}")
        else
          layout = Layout.new
          layout.embed[:main_content] = Ht.compact("div:ezload=[url=#{make_base_url}]")
          @response.body = layout
        end
        return nil
      end
    end

    module Delete
      def public_delete_post
        @id ||= get_id
        dataset = DB.dataset(@column_set.name)
        DB.delete(dataset, @id)
        return public_default
      end
    end
  end
end