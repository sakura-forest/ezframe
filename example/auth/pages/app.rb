# frozen_string_literal: true

module Ezframe
  class App < PageBase
    def initialize(request, model)
      super(request, model)
      mylog "request=#{request.inspect}"
      @column_set = @model.column_sets[:user]
      @dataset = @column_set.dataset
    end

    def public_index_page
      layout = { tag: "ul", child: [
        { tag: "li", child: { tag: "a", href: "/app/test1", child: "test1"}},
        { tag: "li", child: { tag: "a", href: "/app/test2", child: "test2"}},
      ] }
      common_page(title: "Top", body: Html.wrap(Materialize.convert(layout)))
    end

    alias_method :public_default_page, :public_index_page

    def public_test1_page
      common_page(title: "Public1 Page", body: Html.wrap(Materialize.convert({ tag: "h1", child: "test1"})))
    end

    def public_test2_page
      common_page(title: "Public2 Page", body: Html.wrap(Materialize.convert({ tag: "h1", child: "test2"})))
    end
  end
end
