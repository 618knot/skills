# animated-diagram

HTMLドキュメント・技術記事・設計書・チャット解説の「挿絵（インライン図解）」としてスッと挟める、**Stripe / Cloudflare ブログや ByteByteGo 図解のようなコンパクトなアニメーション付き構成図・フロー図**を生成する Agent Skill です。

---

## コアコンセプト（6大設計原則）

1. **Zero-Player Chrome**: シークバー・倍速・前後ビートボタン・字幕ボックスは置かず、`<figure>` ＋ 1行 `<figcaption>` のスリムな構成（高さ `220〜380px` 目安）に収めます。
2. **Static Backbone, Moving Signal**: 箱・配線・ステップ番号（`①`, `②`）を完全固定し、静止画でも100%読める骨格の上を信号パケットと控えめな発光だけが流れます。
3. **Single-Wave Cadence & Rest Dwell**: 全矢印の点線を常時チカチカさせるのを避け、1トランザクション完了ごとに **`1200〜1800 ms` の静止休止** を挟みます（同時移動 `<= 4`）。
4. **Micro-Toggle Only**: スライダー群や別枠パネルは作らず、ヘッダー右上の **2〜3個のシナリオ切替ピル** と **`⏸ 停止 / ▶ 再開` ボタン** のみに絞ります。
5. **頻出5大図解パターン**: リクエスト往復図 / 非同期キュー＆並列ワーカー / 縦シーケンス図 / ステートマシン / データ変換パイプラインを使い分けます。
6. **マルチ環境互換（Vanilla CSS 統一）& WCAG 2.2**: Tailwind CDN を含む外部 `<script>` / `<link>` を完全に排除した標準 `<style>`（Vanilla CSS）＋インライン SVG/JS で自己完結するため、CSP 制約下の Claude Desktop / claude.ai Artifacts・Claude Code・Antigravity・技術記事のすべてでそのまま動作します。最小 `12px`、コントラスト `>= 4.5:1`、`:root` 非汚染テーマ対応、`prefers-reduced-motion` 静的矢印フォールバックを徹底します。

---

## 他スキルとの使い分け

| スキル名 | 主な用途・スタイル | プレイヤーUI / 操作系 |
| :--- | :--- | :--- |
| **`animated-diagram`**（本スキル） | 記事・設計書・チャットに挟む**動く挿絵**（構成図・フロー・シーケンス・状態遷移） | シナリオ切替ピル（2〜3個）＋ `⏸ 停止 / ▶ 再開` のみ |
| **`interactive-explanation`** | 読者が変数を動かして仮説検証する**実験室・シミュレータ** | 直接ドラッグハンドル・スライダー・Small Multiples |
| **`explanatory-animation`** | 5幕構成・物語アークで直観を積み上げる**疑似動画シアター** | シークバー・1ビート送り/戻し・倍速・字幕読解待ち（Phase A） |
| **`pr-walkthrough-animation`** | Git PR・ブランチ差分の**変更理由と影響解説ウォークスルー** | 2ペイン再生シアター（Mode A）または音声付き MP4（Mode B） |

---

## セットアップ

リポジトリルートで [setup.sh](../../setup.sh) を実行すると、`~/.gemini/config/skills/animated-diagram` および `~/.claude/skills/animated-diagram` へシンボリックリンクが作成されます。

```bash
./setup.sh
```

---

## プロンプト例（5大図解パターン別）

- **システム構成・リクエスト往復図**:
  - 「Read-Through キャッシュの Cache Hit / Cache Miss の流れがわかるコンパクトな動く構成図を作って」
- **非同期キュー・ワーカー並列パイプライン図**:
  - 「Webhook 受信からキュー投入、3並列ワーカー処理と DLQ 退避の流れを記事挿絵用の動く図解にして」
- **シーケンス図・縦タイムライン**:
  - 「OAuth 2.0 + PKCE の認可フローを、技術ブログにそのまま貼れる動くシーケンス図で作って」
- **ステートマシン・状態遷移図**:
  - 「Circuit Breaker（Closed / Open / Half-Open）の状態遷移図を、障害発生と復旧シナリオ切替付きで動かして」
- **データ/パケット変換パイプライン図**:
  - 「RAG パイプラインでドキュメントが Chunking → Embedding → Vector Search へ変換される様子を挿絵で表現して」

---

## ファイル構成・個別チューニング窓口

| 調整したい項目 | 対象ファイル | 主な内容 |
| :--- | :--- | :--- |
| **発動条件・6大原則・自己監査ゲート** | [SKILL.md](./SKILL.md) | 起動トリガー（`description`）、環境制約、パターン選定表、4ステップ作成手順、8項目監査リスト |
| **5大図解パターン・認知根拠・Gotchas** | [references/diagram-archetypes-and-rules.md](./references/diagram-archetypes-and-rules.md) | MOT/周辺視野/WCAG 定量根拠、5パターンの座標＆ルーティング仕様、10大アンチパターン |
| **HTML/SVG/CSS/JS 実装テンプレート** | [references/implementation-patterns.md](./references/implementation-patterns.md) | `:root` 非汚染 CSS、Single-Wave + Rest Dwell エンジン、Micro-Toggle、自己完結サンプル |
