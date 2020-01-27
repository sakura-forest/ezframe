# ezframe

 ezframeは主にRubyで記述されたウェブフレームワークです。
 以下を目指して開発を進めています。

* Ruby言語でのプログラミングだけでリッチなGUIを持つウエブアプリを作れる。
* 最小の学習コストで、最大限の自由で柔軟な開発スキルを得られる。
* コードの再利用性を高める。
* 他ライブラリーへの依存は極力少なくし、見通しの良くする。

## 基本的な使い方

1. レポジトリーの取得
```sh
git clone git@github.com:sakura-forest/ezframe-template
cd ezframe-template
bundle install --path vendor/bundle
```

2. columns/に、データ項目を記したyamlファイルを生成します。
  ここではcolumns/address.ymlという名前のファイルを作ります。

```yaml
- key: name
  label: 氏名
  type: jpname
- key: email
  label: E-mail
  type: email
```

3. データを編集する機能を実装します。
  

3. データベースの生成
  データベースにaddressテーブルを作ります。
  デフォルトではdb/dev.sqliteを生成します。

```sh
$ bundle exec create_tables.rb
```

5. アプリケーションサーバーの起動

　サーバーが起動します。デフォルトでは9292番ポートが使われます。

```sh
bundle exec rackup
```

6. ブラウザで(http://localhost:9292)を開きます。
