class Japanese
  class << self
    def convert_wareki(year)
      [
        ["令和", 2019],
        ["平成", 1989],
        ["昭和", 1926],
        ["大正", 1912],
        ["明治", 1868],
      ].each do |a|
        gengo, start_at = a
        wareki = year - start_at + 1
        if wareki > 0
          wareki = "元" if wareki == 1
          return "#{gengo}#{wareki}"
        end
      end
    end

    def is_katakana?(str)
      return nil if !str || str.empty?
      return /^[ァ-ン\-ー―−]+$/ =~ str
    end

    def is_hiragana?(str)
      return nil if !str || str.empty?
      return /^[ぁ-ん\-ー―−]+$/ =~ str
    end

    def to_hiragana(str)
      return nil if !str
      return str.tr("ァ-ン\-ー―−", "ぁ-ん\-ー―−")
    end

    def to_katakana(str)
      return nil if !str
      return str.tr("ぁ-ん\-ー―−", "ァ-ン\-ー―−")
    end

    def to_wday(wday)
      return nil unless wday
      return %w(日 月 火 水 木 金 土)[wday]
    end

    def to_datetime_str(tm)
      return nil unless tm
      return "%d年%2d月%2d日 %2d:%02d:%02d" %[ tm.year, tm.mon, tm.mday, tm.hour, tm.min, tm.sec ]
    end

    def to_date_str(tm)
      return nil unless tm
      return "%d年%2d月%2d日" %[ tm.year, tm.mon, tm.mday]
    end
  end
end
