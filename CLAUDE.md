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
