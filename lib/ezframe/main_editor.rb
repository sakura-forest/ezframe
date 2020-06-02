# frozen_string_literal: true
require_relative "main_page_kit"

module Ezframe
  class MainEditor < PageBase
    include EditorCommon

    def route
      case path
      MainPageKit::Default
      MainPageKit::Index
      MainPageKit::Edit
      MainPageKit::Detail
  end
end
