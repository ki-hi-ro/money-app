# Herokuへの反映

対象URL: https://money-app-khiro-a414f54be759.herokuapp.com/

## 現在の進捗

- ローカルでの複数ユーザー対応、認証、計算の回帰テストは完了。
- Heroku CLIの認証は2026-09-24に完了。稼働スタックはheroku-22。
- 本番DBは利用者0人、旧投稿1件、日記0件。変更前リリースはv30、バックアップb001の取得が完了。
- iCloud SMTPと公開ホストの設定を反映済み（v31）。アプリ用パスワードの設定、アプリのデプロイ、メール動作確認は未完了。
- ローカルの移行候補は利用者1人、資産口座11件、カード1件、入出金176件、タスク1件、資産履歴10件。読み取り専用で所有者の一致を確認済み。本番の対象テーブルが空であることを再確認して取り込み、旧投稿は保持する。
- Ruby 3.3.12 / Rails 8.1.3.1に更新済み。Rails 7.1、7.2、8.0、8.1の順で互換性を検証し、最終環境で34件のテストが成功。
- JSONはRails 8.1の引数仕様に合わせて2系、Minitestはテスト実行基盤に合わせて5系を指定。Linux向け依存ロックを含む。

## 認証後の手順

1. `heroku apps:info --app money-app-khiro` でURL、アプリ所有権、スタックを確認する。
2. DBの利用者数・マイグレーション状態を読み取り、ローカルと本番のアカウントを照合する。ローカルDBを本番へ上書きしない。ローカルの家計情報を移す場合は、対象利用者を確定して選択的に取り込む。
3. 本番設定は値をログへ出さず、必要なキーの有無を確認する。`.env.example` にあるSMTP情報を送信サービスの設定から取得する。架空のSMTP情報や開発用ファイル配送で代用しない。
4. `APP_HOST` は `money-app-khiro-a414f54be759.herokuapp.com` に設定し、`MAIL_FROM` は送信サービスで認証済みのアドレスを使う。既存の `DATABASE_URL`、`SECRET_KEY_BASE`、`RAILS_MASTER_KEY` は保持する。
5. `heroku pg:backups:capture --app money-app-khiro` を実行し、バックアップの完了を確認する。デプロイ前のリリース番号も記録する。
6. テスト済みのソースを反映する。Procfileのrelease処理が設定チェックとDBマイグレーションを実行し、失敗した場合は新しいwebプロセスをリリースしない。
7. HTTPS、未ログイン時のアクセス制限、既存アカウントのログイン、登録確認・パスワード再設定メールの到達、別ユーザー間のデータ分離を確認する。

## 注意

- `bin/check-deploy-config` は設定の不足や形式だけを確認する。SMTP認証・配送の成功までは保証しない。
- リリース失敗時でも、すでに完了したDB変更は自動で戻らない。アプリのロールバックとDB復元を混同しない。
- 旧投稿・日記の所有者は、移行時に利用者が1人のときだけ自動設定する。複数人いる場合、未割り当てデータの所有者を確認してから割り当てる。
- 本番の利用者が最初の資産登録を行う場合、カード支払見積もりの初期値は0円。ローカルの個人設定が自動転送されることはない。

参考: [Heroku Release Phase](https://devcenter.heroku.com/articles/release-phase)、[PGBackups](https://devcenter.heroku.com/articles/heroku-postgres-backups)、[Ruby対応状況](https://devcenter.heroku.com/articles/ruby-support-reference)
