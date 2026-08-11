# CLAUDE.md

簡易版。後ほどブラッシュアップ予定。

## このリポジトリについて

- [IELTS Creator](https://github.com/h-fujiwara-dev/ielts-creater) のAWSインフラ（Terraform）
- プロジェクト全体の要件・アーキテクチャ（AWS構成図含む）は[ielts-createrリポジトリ docs/システム要件定義書.md 8章](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/システム要件定義書.md#8-アーキテクチャ)を参照
- インフラ構築はロードマップ上のPhase 3から着手（[ロードマップ.md](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/docs/ロードマップ.md)）

## 言語ポリシー

- 日本企業向けポートフォリオとして公開するため、**ドキュメント・コメント・コミットメッセージは日本語**で記載する
- リソース名・変数名等は英語のまま実装する

## コミットメッセージ規則

- 書式: `[#チケット番号] type: 概要（日本語）`（例: `[#00001] feat: リポジトリ新規構築`）
- チケット番号は5桁ゼロ埋め。typeはConventional Commits準拠（feat/fix/docs/style/refactor/test/chore/perf/build/ci/revert）
- ielts-creater / -frontend / -backend / -infra の4リポジトリ共通のルール
- テンプレートは `.gitmessage`（`git config commit.template .gitmessage` で有効化済み。cloneし直した場合は再設定が必要）
- チケット番号は[ielts-createrリポジトリ tickets/](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/tickets/)で採番・管理する

## ブランチ戦略

このリポジトリのみ、Terraformの環境分離（`terraform/envs/dev` / `terraform/envs/prod`）に対応させて環境ごとにブランチを分ける（frontend/backend/rootは`develop`/`main`の2ブランチ運用のまま。[ielts-creater CLAUDE.md](https://github.com/h-fujiwara-dev/ielts-creater/blob/main/CLAUDE.md)参照）。

```text
main ← develop ← 作業ブランチ   （dev環境向け）
main ← prd     ← 作業ブランチ   （prd環境向け）
```

- `main`: リリース専用ブランチ。直接pushは禁止（管理者含む、PR必須）。`develop`または`prd`からのリリースPRをマージするタイミングのみ更新する
- `develop`: dev環境向けの開発統合ブランチ。直接pushは禁止（管理者含む、PR必須）。dev環境向け作業ブランチのPRはすべてここにマージする
- `prd`: prd環境向けの開発統合ブランチ。直接pushは禁止（管理者含む、PR必須）。prd環境向け作業ブランチのPRはすべてここにマージする
- 作業ブランチ: 対象環境に応じて`develop`または`prd`から作成し、コミットメッセージのtype（Conventional Commits準拠）を接頭辞とする（例: `feat/xxx`, `fix/xxx`, `docs/xxx`, `chore/xxx`）。命名規則自体はdev/prdで変えない
- 作業ブランチをpushすると、GitHub Actionsが分岐元（`develop`/`prd`）をmerge-baseで自動判定し、対応するブランチ宛にPRを作成する（[.github/workflows/auto-pr.yml](./.github/workflows/auto-pr.yml)）
- `develop`→`main`または`prd`→`main`のリリースPRは[.github/workflows/release-pr.yml](./.github/workflows/release-pr.yml)を`workflow_dispatch`で手動実行して作成する（`source`入力でdevelop/prdを選択。botがPRを作成するため、ユーザー自身がapproveできる）
- 全PR（`develop`・`prd`・`main`とも）はマージ前にユーザーのapprove（レビュー1件）が必須（`required_approving_review_count: 1`、管理者もバイパス不可）。markdownlint必須チェックも従来通り適用
- ベースブランチ（`develop`/`prd`/`main`）へのpush時、オープン中のPRを自動で最新化する（[.github/workflows/auto-update-branch.yml](./.github/workflows/auto-update-branch.yml)）。「out-of-date」表示による手動更新操作は基本不要になる
