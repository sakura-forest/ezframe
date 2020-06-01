# frozen_string_literal: true
require_relative "main_page_kit"

module Ezframe
  class MainEditor < PageBase
    include EditorCommon
    include MainPageKit::Default
    include MainPageKit::Index
    include MainPageKit::Edit
    include MainPageKit::Detail
  end
end
