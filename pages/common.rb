module Ezframe
  module PageCommon
    def sidenav
      [ 
        { tag: "a", href: "/admin", child: { tag: "img", src: "https://img.sakura-forest.com/asset/images/content/logo.png" } },
        { tag: "br" },
        { tag: "form", method: "post", action: "/admin/search", child: [
          { tag: "input", type: "text", name: "word", id: "word" }, 
          { tag: "input", type: "hidden", name: "dummy", value: 1},
          { tag: "button", type: "submit", class: %w[btn-small], child: { tag: "icon", name: "search" } } 
        ]},
        { tag: "br" },
        { tag: "a", href: "/admin/new", child: "新規顧客登録" } 
      ]
    end
  end
end