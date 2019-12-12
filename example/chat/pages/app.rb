# frozen_string_literal: true

module Ezframe
  class App < PageBase
    def initialize(request=nil, model=nil)
      super(request, model)
      if @request
        mylog "request=#{@request}"
      end
      if @model
        @column_set = @model.column_sets[:user]
        @dataset = @column_set.dataset
      end
      @auth = true
    end

    def public_index_page
      hthash = { tag: "ul", child: [
        { tag: "li", child: { tag: "a", href: "/app/test1", child: "app1"}},
        { tag: "li", child: { tag: "a", href: "/app/test2", child: "app2"}},
      ] }
      common_page(title: "app Top", body: Html.wrap(Materialize.convert(hthash)))
    end

    def public_test1_page
      common_page(title: "Secret Page", body: Html.wrap(Materialize.convert({ tag: "h1", child: "test1"})))
    end

    def public_test2_page
      common_page(title: "Secret Page", body: Html.wrap(Materialize.convert({ tag: "h1", child: "test2"})))
    end

    def public_default_page
      mylog "login?: #{login?}"
      if login?
        public_index_page
      else
        public_login_page
      end
    end

    def public_login_page
      form = { tag: "div", class: %w[container], child: 
        { tag: "form", action: "/app/login", method: "post", child: [
          { tag: "input", type: "text", name: "account", label: "User ID"},
          { tag: "input", type: "password", name: "password", label: "Password"},
          { tag: "button", type: "submit", class: %w[btn], child: "login"}
        ]}
      }
      common_page(title: "Login", body: Html.wrap(Materialize.convert(form)))
    end

    def public_login_post
      mylog "public_login_post: #{@params.inspect}, #{@json}"
      warden.authenticate # (@params["account"], @params["password"])
      public_index_page
    end
  end
end