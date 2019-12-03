# ezframe

ezframeは主にRubyで記述されたウェブフレームワークです。
最小の学習コストで、最大限の柔軟性を実現することを目指して開発しています。

## 使い方

1. レポジトリーの取得
```sh
git clone git://github.com/sakura-forest/ezframe
cd ezframe
```
2. columns/に、データ項目を記したyamlファイルを生成
  例: vi model/user.yml

```yaml
- key: name
  label: 氏名
  type: jpname
- key: email
　label: E-mail
  type: email
```

3. 使用する機能を選択
  例：データ編集 vi view/user.rb

```ruby
class EzController
  def init_hook
    @main_columnset = "user"
  end
end
```
  
4. データベースの生成
```sh
$ rake db:create
```

5. アプリケーションサーバーの起動
rake server

