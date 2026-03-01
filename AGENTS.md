# AGENTS.md

## Project Preferences
- テストコードは作成しない。
- `flutter test` / `dart test` / `integration_test` は、ユーザーが明示的に依頼した場合を除き実行しない。
- 品質確認が必要な場合は、まず手動確認手順の提示を優先する。

## Scope
- この方針は `/Users/wakabayashishuntaira/Documents/garake` 配下の作業に適用する。

## Project Description
ガラケー風のアプリです。
取った写真がガラケー風の画質になるアプリです。
保存したり、SNSにシェアできたりします。
UIは定期的に変更するので変更しやすいようなアーキテクチャを採用してください。
1ファイルは最大で500行までとします。
また何してるのかが人間にもAIにもわかりやすいように一言でコメントを追加してください。
また、依存してるファイルと何で依存しているか、どんなメソッドを必要としているか、どんなメソッドを提供しているかも抽象化しつつ書いてほしいです。

目指しているデザインは
IMG_2195.JPG
です。これを参考にしてください。

フレームワークは
/Users/wakabayashishuntaira/Documents/garake/framework.JPG