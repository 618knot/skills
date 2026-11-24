# pr-walkthrough-animation

Git の Pull Request・ブランチ差分・未コミット変更を自律解析し、**「生 diff の丸映し」を排して、変更理由（Why）・構造変化・核心コード抜粋・破壊リスク／類似箇所への波及**を時間軸のアニメーションで解説する Agent Skill です。

---

## 2つの出力モード（自動判定）

| モード | 出力形式 | 特徴・向いている用途 | 追加ツール要件 |
| :--- | :--- | :--- | :--- |
| **Mode A（デフォルト）** | 無音 HTML / SVG 再生シアター | チャット・ブラウザ上でゼロ依存即再生。再生/一時停止・1ビート戻し/送り・速度変更・`file:line` バッジ連動付きで、自分の手元確認に最適。 | **なし** |
| **Mode B（動画ファイル指定時）** | 音声ナレーション付き MP4 / WebM ＋ WebVTT 字幕 | 「MP4」「音声付き」指定時に選択。TTS 先生成の Audio-First 同期・GitHub PR 添付互換（H.264 `yuv420p`・`9.5 MB` 以下）・ミュート冒頭完結設計。 | TTS（VOICEVOX / ElevenLabs 等）、Remotion または Playwright、`ffmpeg` |

---

## 前提条件とセットアップ

- **Mode A（デフォルト）は必須の事前設定なし**でそのまま利用できます。
  - GitHub 上の PR を番号/URL 指定で取得する場合のみ GitHub CLI（`gh auth status`）の認証が必要です（ローカルの `git diff` や現在ブランチ差分のみなら不要）。
- **スキルの有効化**：リポジトリルートで [setup.sh](../../setup.sh) を実行すると、`~/.gemini/config/skills/pr-walkthrough-animation` および `~/.claude/skills/pr-walkthrough-animation` へシンボリックリンクが張られます。

```bash
./setup.sh
```

---

## 使い方の例

### Mode A（HTML/SVG 再生シアター：デフォルト）
- 「このPRの内容をアニメーションで解説して」
- 「PR #142 の変更をウォークスルー動画にして」
- 「`main` とのブランチ差分を動きで理解したい」
- 「今の未コミット変更のフローをアニメで説明して」

### Mode B（音声ナレーション付き MP4 動画）
- 「PR #142 の音声付き解説動画を MP4 で作って（GitHub PR に貼れる 9.5MB 以下で）」
- 「VOICEVOX と Remotion（または Playwright + FFmpeg）を使って、このブランチの PR解説動画を作って」

### `pre-review-quiz` との併用フロー
1. まず **`pr-walkthrough-animation`** で「変更の全体像・データフロー・リスク箇所」を視覚的に把握する。
2. 続けて **`pre-review-quiz`** で「本当に境界条件や副作用を説明できるか」を1問ずつテストして仕上げる。

---

## ファイル構成・個別チューニング窓口

| 調整したい項目 | 対象ファイル | 主な内容 |
| :--- | :--- | :--- |
| **発動条件・6フェーズ構成・自己監査ゲート** | [SKILL.md](./SKILL.md) | 起動トリガー（`description`）、Mode A/B 判定、5-Stage フロー、バイナリ監査チェックリスト |
| **PR解析・クラスタリング・中間JSON仕様** | [references/pr-analysis-and-storyboard.md](./references/pr-analysis-and-storyboard.md) | 差分取得・ノイズ除外・裏取り・最大3関心事クラスタ・PRタイプ別比率・4ブロック中間JSON |
| **ビジュアル規約・1080p可読性・10大Gotchas** | [references/code-visual-patterns.md](./references/code-visual-patterns.md) | 6フェーズ別視覚語彙、Magic Move / 左右分割同時表示、コード行数/文字数上限、10大アンチパターン |
| **Mode A（無音 HTML/SVG シアター）実装** | [references/theater-engine-patterns.md](./references/theater-engine-patterns.md) | 無音5フェーズ同期エンジン、2ペイン／分割コード描画、Progressive Path 残像、`prefers-reduced-motion` |
| **Mode B（音声付き MP4 動画）パイプライン** | [references/narrated-video-pipeline.md](./references/narrated-video-pipeline.md) | TTS原稿/SSML規約、Audio-First 同期（ElevenLabs / VOICEVOX / WhisperX）、FFmpeg 9.5MB 自動フォールバック |
