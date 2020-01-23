# ezframe

 ezframeは主にRubyで記述されたウェブフレームワークです。
以下を目指して開発を進めています。

* Ruby言語でのプログラミングだけでリッチなGUIを持つウエブアプリを作れる。
* 最小の学習コストで、最大限の柔軟性を実現する。
* コードの再利用性を高める
* 他ライブラリーへの依存は極力少なくし、見通しの良さ

## 基本的な使い方

1. レポジトリーの取得
```sh
git clone git@github.com:sakura-forest/ezframe.git
cd ezframe
bundle install --path vendor/bundle
bundle exec rackup
```

2. columns/に、データ項目を記したyamlファイルを生成
  例: vi columns/address.yml

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
