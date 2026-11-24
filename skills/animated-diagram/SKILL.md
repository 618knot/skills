---
name: animated-diagram
description: >-
  Design and build compact inline animated architecture, flow, sequence, state, and pipeline diagrams (HTML/SVG/CSS/JS) that embed cleanly into HTML documents, technical articles, design docs, and chat explanations as Stripe/Cloudflare/ByteByteGo-style illustrations.
  Grounds motion in perception limits and cognitive load theory (Pylyshyn MOT <= 4, Bartram & Ware peripheral distraction restraint, Boucheix & Lowe Progressive Path, Sweller spatial contiguity, WCAG 2.2) using a static readable backbone, single-wave signal cadence with rest dwell, and minimal scenario/pause micro-toggles.
  Use whenever the user asks for a compact animated diagram or inline flow illustration (e.g., "動く構成図を作って", "アニメーション付きフロー図", "リクエストやデータの流れがわかる挿絵", "動くシーケンス図", "状態遷移図をアニメーションで", "記事・設計書に挟めるコンパクトな動く図解", "ByteByteGo風 / Stripeブログ風の構成図").
  Do NOT use for full multi-act narrative playback theaters with seekbars, speed controls, and subtitle dwell (use explanatory-animation), hands-on parameter-exploration labs and sandboxes (use interactive-explanation), or Git PR/branch diff walkthroughs (use pr-walkthrough-animation).
---

# Animated Inline Diagram Skill

HTMLドキュメント・技術記事・設計書・チャット解説の「挿絵（インライン図解）」として読解を妨げずに挟める、**コンパクトで静的に完結しつつ信号の流れが直観的にわかるアニメーション付き構成図・フロー図**を設計・実装するためのスキル。

- **適用判定ゲート**：リクエスト往復・状態遷移・非同期キュー・プロトコルハンドシェイク・データ変換など**「固定されたトポロジー上の流れ・状態変化」を記事やチャットの文脈を止めずに直観化する場面**に適用する。
  - 変化を伴わない純粋な静的配置比較は静的SVG（`Ploetzner et al., 2020`: $g = 0.043$）、読者が変数を操作して仮説検証する実験室UIは `interactive-explanation`、5幕構成の物語と字幕読解待ちを備えた解説シアターは `explanatory-animation`、Git差分解説は `pr-walkthrough-animation` を用いる。

> [!IMPORTANT]
> **マルチ環境互換（Claude Artifacts / Claude Code / Antigravity / 記事埋め込み）の必須制約**
> 1. **完全ゼロ依存・外部CDN全面禁止（CSP互換・Vanilla CSS 統一）**: Tailwind CDN を含む外部CSS・フォント・アイコン・JSライブラリ（GSAP / D3 / Mermaid CDN 等）の `<script>` / `<link>` を一切読み込まない。単一 `.html` 内の **標準 `<style>`（Vanilla CSS）＋インライン SVG/JS** のみで自己完結させ、CSP 制限下にある Claude Desktop / claude.ai の Artifacts やオフライン環境でもそのまま確実に動作させる。
> 2. **`:root` へのローカル色定義禁止＆セマンティックテーマ変数**: `:root { --bg: ... }` のようなローカル色定義、およびホスト内部トークン（`--vscode-*`, `--app-*`）の参照を禁止する。ホスト注入トークン（`--background`, `--card`, `--card-border`, `--border`, `--foreground`, `--muted-foreground`, `--primary`, `--primary-foreground`, `--secondary`, `--secondary-foreground`, `--success`, `--warning`, `--error`, `--chart-1`〜`--chart-6`）があれば優先継承し、Claude Artifacts や単体ブラウザ等の未定義環境では `html { color-scheme: light dark; }` ＋要素ルール側の `var(--card, light-dark(#ffffff, #18181b))` 等でライト/ダーク自動適応する（`<canvas>` 併用時は `themechange` と `prefers-color-scheme` 変更で状態を保ち再描画）。
> 3. **ホスト環境別の出力とコンパクト寸法予算**:
>    - **Claude 環境（Claude Desktop / claude.ai Artifacts、Claude Code）・技術記事・一般ブラウザ**: 単一の自己完結 HTML（または記事内 `<figure>` スニペット）として出力する。
>    - **Antigravity 環境（`generative_ui` 利用可能時）**: `<body class="is-inline">` で `background: transparent; margin: 0; padding: 0` とし、外側カード枠の二重囲みを避けて `<agent-embed>` でインライン埋め込みする。
>    - いずれの環境でも全体の高さは **`220〜380px` 標準（上限 `<= 420px`）** に収め、トップレベル要素への `100vh` / `min-h-screen` / `height: 100%` は高さ崩壊を招くため厳禁とする。

---

## 1. 「動く挿絵」の6大設計原則（Core Principles）

1. **Zero-Player Chrome（動画UI・字幕待ちの廃止）**
   - シークバー、前後ビート送り、倍速選択、映画風の下部字幕ボックス、数秒間の字幕読解待ち（Phase A）を置かない。`<figure>` と **1行 `<figcaption>`** で完結するスリムな挿絵構造にし、本文の読解リズムを分断しない（Mayer Redundancy $d = 0.86$ / Coherence $d = 1.66$）。
2. **Static Backbone, Moving Signal（骨格完全固定・信号のみ移動）**
   - コンポーネント箱・配線レール・ステップ番号／役割ラベル（`① GET /items`, `② Lookup` 等）の座標は完全固定し、**どの瞬間にスクリーンショットを撮っても100%構造と順序が読める** Static-First 設計とする（Tversky Apprehension Principle / Robertson et al., 2008）。独立凡例ボックス（Legend）は廃止し直近ラベルで空間統合する（Chandler & Sweller Split-Attention 排除）。
   - 動かす対象は次の4種に厳しく限定する：(a) 配線上を走る信号パケット、(b) 通過中エッジの Progressive Path 発光（Boucheix & Lowe, 2010）、(c) 処理中ノードの控えめな枠線／バッジ強調（誇張バウンス Squash & Stretch 禁止）、(d) 状態／シナリオ切替時の短い遷移（`300–600 ms` Cubic Slow-in/Slow-out、意味的対応のある同一要素のみ）。
3. **Single-Wave Cadence & Rest Dwell（クリスマスツリー化の禁止）**
   - 全矢印の点線を常時一斉に行進させる（Marching Ants）や待機スピナーの常時回転は、周辺視野の運動検出（約 `1秒`・誤検出率ほぼ `0%`：Bartram & Ware, 2002）を絶えず捕捉して本文読解を妨害するため厳禁とする。
   - 原則 **1トランザクション（1〜2トークン、並列分岐でも同時独立移動 `<= 4`、5以上は Common Fate グループ化：Pylyshyn & Storm, 1988）** が順番に流れて完了した後、**`1200〜1800 ms` の完全静止休止（Rest Dwell）** を挟んで次の一波を流す（同一地点の通過頻度は `< 3回/秒`）。
4. **Micro-Toggle Only（最小限のピル切替＋停止ボタン）**
   - スライダー群や別枠のコントロールパネルは作らない。UI を設ける場合もスリムヘッダー右上の **2〜3個のシナリオ切替ピル**（例：`Cache Hit` / `Cache Miss`、`正常系` / `障害フォールバック`）と **`⏸ 停止 / ▶ 再開` トグルボタン**（WCAG 2.2 SC 2.2.2）、および任意の**ノード／経路ホバーハイライト**（非関連要素を `opacity: 0.25` へ減光、初期状態でラベルを隠す覗き穴UIは禁止）のみに留める。
5. **頻出5大図解パターンの網羅**
   - 題材を単調な横一列の箱図に押し込めず、因果構造に応じて **(1) システム構成・リクエスト往復図、(2) 非同期キュー・ワーカー並列パイプライン図、(3) シーケンス図（縦タイムライン）、(4) ステートマシン・状態遷移図、(5) データ/パケット変換パイプライン図** を適切に使い分ける。
6. **マルチ環境互換・アクセシビリティ規約（Vanilla CSS & WCAG 2.2）**
   - 実効描画サイズ最小 `12px`（SVG内 `<text>` 含む）、ボタン・バッジの文字コントラスト比 `>= 4.5:1`（非テキストUI・信号線 `>= 3:1`）、タッチターゲット `min-block-size: 24px` かつ `min-inline-size: 24px`。
   - ネイティブ `<button type="button">` ＋ `aria-pressed` ＋ `:focus-visible` アウトライン、`<svg role="img" aria-labelledby="...">` ＋ `<title>` / `<desc>` を必須とする。図内・`<figcaption>` のテキストに `user-select: none` を指定してはならない。
   - `prefers-reduced-motion: reduce` 検知時は自動停止し、**色付き矢印＋番号ラベルだけで完全に読解できる静的表示**へ切り替える（`* { animation-duration: 0.01ms !important }` のような雑な一括リセットは厳禁）。

---

## 2. 頻出5大図解パターンの選定マトリクス

👉 **各パターンの座標設計・配線分離ルール・10大アンチパターン（Gotchas #1–#10）と定量的根拠の詳細は [references/diagram-archetypes-and-rules.md](./references/diagram-archetypes-and-rules.md) を参照。**

| # | パターン | 向いている題材 | 骨格レイアウトと高さ予算 | 信号・状態の動き方 | シナリオ切替ピル例 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **システム構成・リクエスト往復図**<br>(Request-Response) | CDN/Cache、API Gateway、認証、Read/Write 分離 | 3〜6ノード横配列または2段グリッド。往路（上側）＋復路（下側）平行分離。高さ `220–320px` | 往路ホップ順に信号1個が移動＋Progressive発光 → 復路へ折り返し → Rest Dwell | `Cache Hit` / `Cache Miss`<br>`正常系` / `Circuit Open` |
| **2** | **非同期キュー・ワーカー並列**<br>(Async Queue & Fan-out) | メッセージキュー、Webhook配信、ジョブワーカー、DLQ | Producer → Queue（可視セル枠） → Worker 1〜3並列 → Store/DLQ。高さ `250–340px` | 同期 `202` 応答と、Queue からの並列分配（同時 `<= 4` / Common Fate）を前後半で表現 | `通常処理` / `リトライ→DLQ`<br>`単一` / `並列スケール` |
| **3** | **シーケンス図・縦タイムライン**<br>(Vertical Sequence) | OAuth/OIDC、TLSハンドシェイク、2PC、分散トランザクション | 上部固定アクター3〜4列＋縦破線＋薄いアクティベーション矩形＋3〜6段矢印。高さ `280–380px` | 上段から1段ずつ信号が横移動し、完了段に控えめな点灯履歴を残して全段完了後に休止 | `新規認可` / `Token更新`<br>`成功` / `競合リトライ` |
| **4** | **ステートマシン・状態遷移図**<br>(State Machine) | 接続状態、注文ライフサイクル、Saga、Circuit Breaker | 初期 `●→` ＋状態ノード3〜5個＋上下分離カーブ＆自己ループ＋ガードラベル固定。高さ `230–320px` | 遷移アークを信号が走ると同時に、遷移先状態ノードの枠線・背景色が `300–500ms` で切替 | `正常遷移` / `タイムアウト`<br>`Closed→Open` / `Half-Open` |
| **5** | **データ/パケット変換パイプライン**<br>(Transformation Pipeline) | コンパイラ、シリアライザ、ETL、暗号化/署名、中間表現 | 上段：変換ステージ3〜4箱、下段：各段階の具体ミニデータ例（`12px` mono）常時並置。高さ `240–330px` | パケットがステージ箱を通過するたびに型・色バッジが変化し、対応する下段スナップショットが点灯 | `JSON変換` / `バイナリ圧縮`<br>`検証成功` / `スキーマ拒否` |

---

## 3. 必須設計・実装ワークフロー（4-Step Workflow）

1. **Step 1：1図1命題の絞り込みとパターン選定**
   - 挿絵が伝える核心命題を1文（`<figcaption>` 用、1行目安）に絞り、ノード数 `3〜7個`・ステップ数 `2〜6ホップ` に整理して上記5パターンから1つ選ぶ。対比すべき分岐がある場合のみ **2〜3個のシナリオ切替ピル** を設計する。
2. **Step 2：静的骨格・実寸 `viewBox`・近接ラベル設計**
   - 横幅の縮小で文字が `12px` 未満にならないよう SVG `viewBox` 幅を `620〜720`（標準高さ `210〜320`）に設定し、SVG `<text>` は `font-size="12"` 以上を保つ。
   - 往路と復路の平行オフセット分離（`±8px` 以上）、番号付き固定ラベル（`①`, `②`...）の配線直近配置、4ノード超の2段グリッド＋角丸直交エルボー配線を確定し、**静止画として読解できる骨格**を先に完成させる。
3. **Step 3：Single-Wave + Rest Dwell 決定論エンジン＆ Micro-Toggle 実装**
   - 👉 [references/implementation-patterns.md](./references/implementation-patterns.md) を読み込み、単一時刻状態から全エッジ・パケット・アクティブノードを純粋計算する `evaluateWave(scenario, elapsedMs)` と、`restDwellMs`（`1200–1800 ms`）、`dt <= 100 ms` クランプ、`IntersectionObserver` サスペンドを組み込む。
   - `<button type="button" aria-pressed="...">` によるシナリオピル・停止/再開トグル、および `prefers-reduced-motion: reduce` 時の静的矢印＋番号表示フォールバック（`.is-static` 切替）を実装する。
4. **Step 4：出力前 8項目自己監査ゲート**
   - 出力直前に第4節の8項目をすべて検査し、1項目でも違反があれば該当箇所を修正してから出力する。

---

## 4. 出力前 8項目自己監査チェックリスト（Binary Self-Audit Gate）

- [ ] **監査1（Zero-Player Chrome & 寸法予算）**: シークバー・前後ビート送り・倍速・下部字幕ボックス・字幕待ち時間がゼロで、`<figure>`＋1行 `<figcaption>` の高さが **`220〜380px` 目安（`<= 420px`）** に収まり、`100vh` / `height: 100%` 依存がないか。
- [ ] **監査2（Static Backbone & 凡例廃止）**: 箱・配線・ステップ番号・直近ラベルがすべて固定されており、任意の静止フレームで100%意味が通るか。独立凡例ボックスやホバー限定隠し情報がゼロか。
- [ ] **監査3（Single-Wave & Rest Dwell）**: 常時点線行進（Marching Ants）や常時回転スピナーがなく、同時独立移動トークン `<= 4`（5以上は Common Fate）で、1波完了後に **`1200〜1800 ms` の静止休止** があるか。
- [ ] **監査4（Micro-Toggle 限定）**: スライダーや別枠設定パネルを置かず、操作要素はヘッダーの **2〜3個以内のシナリオピル** と **`⏸ 停止 / ▶ 再開` ボタン**（＋任意のホバー経路ハイライト）のみに絞られているか。
- [ ] **監査5（図解パターン適合＆配線分離）**: 題材の構造に合った5大パターンを選び、往復エッジの平行オフセット分離やノード間の余白・可読性が確保されているか。
- [ ] **監査6（視認性＆ゼロ依存CSS）**: SVG内文字を含め実効描画サイズが **`>= 12px`**、ボタン・バッジ文字のコントラストが **`>= 4.5:1`**、`:root` へのローカル色定義および Tailwind CDN を含む外部 `<script>` / `<link>` がゼロで標準 `<style>`（Vanilla CSS）のみで完結しているか。
- [ ] **監査7（セマンティックHTML/SVG & 操作性）**: ボタンが `<button type="button">`＋`aria-pressed`＋`:focus-visible` で **`min-block-size: 24px` / `min-inline-size: 24px`** を満たし、`<svg role="img">`＋`<title>`/`<desc>` があり、図内文字に `user-select: none` が付いていないか。
- [ ] **監査8（`prefers-reduced-motion` 静的フォールバック）**: `prefers-reduced-motion: reduce` 時に `* { animation-duration: 0.01ms }` のような雑なリセットではなく、信号移動を止めて**色付き矢印＋番号ラベルの静的完成状態**へ切り替わるか。

---

## 5. リファレンス一覧（Progressive Disclosure）

- **[references/diagram-archetypes-and-rules.md](./references/diagram-archetypes-and-rules.md)**: 挿絵フォーマット向け認知科学・WCAG 2.2 定量根拠一覧、5大図解パターンの詳細レイアウト＆信号ルーティング設計、AIがやりがちな10大アンチパターン（Gotchas #1–#10）。
- **[references/implementation-patterns.md](./references/implementation-patterns.md)**: `:root` 非汚染セマンティック CSS ベース、Single-Wave + Rest Dwell 決定論エンジン、`IntersectionObserver` 省電力制御、Progressive Path ＋曲線追従ヘルパー、Micro-Toggle & `prefers-reduced-motion` 静的フォールバック、Request-Response 完全動作テンプレート＆各パターン用 SVG スニペット。
