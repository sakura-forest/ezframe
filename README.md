# ezframe

ezframeは主にRubyで記述されたウェブフレームワークです。
最小の学習コストで、最大限の柔軟性を実現することを目指して開発しています。

## 使い方

1. レポジトリーの取得
```sh
git clone git@github.com:sakura-forest/ezframe.git
cd ezframe
bundle install --path vendor/bundle
```
2. columns/に、データ項目を記したyamlファイルを生成
  例: vi columns/user.yml

```yaml
- key: name
  label: 氏名
  type: jpname
- key: email
　label: E-mail
  type: email
```

3. データベースの生成
```sh
$ bin/create_tables
```

4. 使う機能の選択
* Todo..

5. アプリケーションサーバーの起動
```sh
bundle exec rackup
```
