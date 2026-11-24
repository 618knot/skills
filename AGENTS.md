# Repository Rules: Multi-Environment Skill Authoring

このリポジトリの `skills/<skill-name>/` にスキルを作成・更新するすべてのエージェントおよびコントリビューターは、以下のルールを必ず遵守すること。

## 1. 前提：マルチ環境配布リポジトリ

- `skills/<skill-name>/` 配下のスキルは `setup.sh` により **Antigravity**（`~/.gemini/config/skills`）と **Claude**（`~/.claude/skills`、および Claude Desktop / claude.ai）の双方へ配布され、同じファイルが両環境から読み込まれる。
- スキルを作成・編集する際、現在作業しているエージェント自身の組み込みスキルや専用機能（例：Antigravity の `generative_ui`、`ArtifactMetadata` / `UserFacing`、`<agent-embed>`、または特定エージェント専用のツール名・組み込みコマンド）を**唯一の必須前提**としてハードコードしてはならない。
- ホスト固有の最適化や出力形式（例：`<agent-embed>` やインライン埋め込み用の透過背景）を記載する場合は、必ず**環境非依存の汎用出力（単一自己完結 HTML / Markdown / ローカルファイル）をデフォルト**とし、ホスト固有仕様は「Antigravity 環境（`generative_ui` 利用可能時）では〜」のように条件付き分岐として分離すること。

## 2. HTML / SVG / Canvas UI スキルの必須規約（Tailwind・外部CDN禁止／Vanilla CSS 統一）

HTML / SVG / Canvas を生成するスキル（およびその `references/` 内のテンプレート・コードスニペット）では、以下を厳守する。

1. **外部 CDN 全面禁止（CSP・オフライン互換）**
   - Antigravity 専用 URL（`https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js`）や `cdn.tailwindcss.com`、外部 JS/CSS/フォント CDN（GSAP, D3, Three.js, Mermaid CDN, Google Fonts 等）の `<script>` / `<link>` 読み込みを一切行わない。
   - Claude Desktop / claude.ai Artifacts の厳格な CSP 制限下やオフラインのローカルブラウザでもそのまま動作させること。
2. **標準 `<style>`（Vanilla CSS）で自己完結**
   - レイアウト・装飾・アニメーションはすべて単一 `.html` 内の標準 CSS（`<style>`）とインライン SVG / Canvas / JS で完結させる。
   - テンプレートやコードスニペット内に未定義の Tailwind ユーティリティクラス（`flex`, `text-xs`, `bg-[var(--card)]`, `border-[var(--border)]`, `hidden` 等）を残さない。要素の表示切替には Tailwind の `.hidden` ではなく、HTML 標準の `hidden` 属性＋`[hidden] { display: none !important; }` 等を用いる。
3. **テーマ変数の `:root` 非汚染と `light-dark()` フォールバック**
   - ホスト環境が注入するセマンティック変数（`--background`, `--card`, `--card-border`, `--border`, `--foreground`, `--muted-foreground`, `--primary`, `--primary-foreground`, `--secondary`, `--chart-1`〜`--chart-6`）を上書きしないよう、**`:root` でこれらの変数名自体を絶対に再定義しない**。
   - `color-scheme: light dark`（および `html.light { color-scheme: light; } html.dark { color-scheme: dark; }`）を設定したうえで、要素ルール側で `var(--card, light-dark(#ffffff, #18181b))` を直接参照するか、`--ui-*` のような別名エイリアス変数（例：`--ui-surface: var(--card, light-dark(#ffffff, #18181b))`）を経由させる。
4. **`<canvas>` 描画のライブテーマ同期**
   - `light-dark(...)` の生文字列を Canvas 2D API（`ctx.fillStyle` / `ctx.strokeStyle` 等）へ直接渡さない（Canvas 描画色として解釈されず無効になるため）。
   - `getComputedStyle(document.documentElement)` でホスト変数を優先取得し、値が空の場合は `root.classList.contains('dark')` と `window.matchMedia('(prefers-color-scheme: dark)').matches` から 16進カラーへ解決するヘルパーを用意する。
   - テーマ切替イベントは `window.addEventListener('themechange', ...)`（Antigravity）と `window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', ...)`（Claude / 一般ブラウザ）の**両方**を購読し、再生位置や状態を保ったまま再描画する。
5. **iframe / インライン埋め込みの高さ崩壊防止**
   - トップレベルコンテナで `100vh` / `min-height: 100vh` / `height: 100%` のみに依存した高さ指定を行わず、コンテンツ主導の高さ設計にする。
   - インライン透過埋め込み向けに `body.is-inline { background: transparent; padding: 0; }` のような切替クラスを用意しておく。

## 3. 新規スキル作成・更新時のセルフレビュー項目

完了前に以下を確認すること。

- [ ] `gstatic` や `tailwindcss`、外部 CDN URL が混入していないか（`rg -i "tailwindcss|gstatic|cdn\." skills/<skill-name>` が 0 件か。禁止例としての言及のみか）。
- [ ] HTML / JS スニペット内の `class="..."` に未定義の Tailwind ユーティリティクラスが残っていないか。
- [ ] `:root` に `--background` / `--card` / `--foreground` 等のホスト変数名を直接定義していないか。
- [ ] 特定の外部ツール・TTS・ローカルアプリ・特定エージェント専用機能への不要なロックインがないか。
