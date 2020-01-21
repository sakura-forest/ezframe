class BasicPages < Ezframe::PageBase
  def public_default_page
    Html.convert(Ht.h1("Ezframe is working."))
  end
end