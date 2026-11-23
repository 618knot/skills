---
name: explanatory-animation
description: >-
  Design and build time-based explanatory animations, choreographed visual storytelling, and playback theater Web UIs (HTML/SVG/Canvas/CSS/JS) grounded in instructional animation cognitive science, Data Video design spaces, motion perception, and multimedia learning theory (Lowe & Boucheix APM, Shi et al., Amini et al., Heer & Robertson, Mayer CTML, Grant Sanderson / 3Blue1Brown).
  Use whenever the user asks to explain a complex concept, algorithm, math intuition, data flow, or system mechanism through timeline-driven motion, morphing, camera work, step-by-step playback, micro-pacing, Data Videos, or 3Blue1Brown/Manim-style animated explainers (e.g., "アニメーションで解説して", "動きで直観的に見せて", "3Blue1Brown風", "モーショングラフィックスで説明").
  Do NOT use when the user wants a hands-on parameter-exploration lab, direct-manipulation sandbox, or static-first small multiples comparison without narrative playback; use interactive-explanation instead. For explaining Git Pull Requests, branch diffs, or code changes as a walkthrough animation, use pr-walkthrough-animation instead.
---

# Explanatory Animation & Motion Storytelling Skill

時間軸に沿った振付（Choreography）・連続変形（Morphing）・カメラワーク・マイクロペーシングによって概念の成り立ちや因果の流れを直観的に伝達する、**解説アニメーション／再生シアターWeb UI**を自律設計・実装するための実行ルールブック。

- **適用判定ゲート（Ploetzner et al., 2020）**：変化の過程・手続き・加減速・因果伝播そのものが学習対象である場合（$g = 0.340\text{–}0.647$、手続き知識 $d = 1.06$）にのみ本スキルを適用する。変化の特徴を学ぶ必要がない静的配置比較（$g = 0.043$）や、読者がパラメータを直接動かして仮説検証する実験室UIは、静的図解または `interactive-explanation` スキルへ委譲する。

> [!IMPORTANT]
> **Antigravity（`generative_ui`）環境で HTML/SVG/Canvas 出力する際の必須制約**
> 1. **外部CDN禁止（CSP制約）**: 許可された Tailwind スクリプト（`https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js`）以外の外部ライブラリ（GSAP / D3 / Three.js 等）は読み込めない。タイムライン・イージング・SVGモーフィング・カメラ制御はすべて**ゼロ依存のインライン HTML/SVG/Canvas/CSS/JS**で実装する。
> 2. **テーマ変数とライブ同期**: `bg-[var(--card)]`, `text-[var(--foreground)]`, `text-[var(--muted-foreground)]`, `--primary`, `--chart-1`〜`--chart-6` 等のセマンティックトークンを用い、`:root` への独自色フォールバックやハードコード色（`bg-slate-900`, `text-white` 等）を避ける。`<canvas>` 描画は `getComputedStyle(document.documentElement)` で色を取得し、`window.addEventListener('themechange', render)` で状態を保ったまま再描画する。
> 3. **配置・高さ予算**: コンパクトな解説シアター（`<= 450px` 目標、`<body class="bg-transparent ... p-0 m-0">`、`h-screen`/`100vh`/`height: 100%` 禁止）はインライン埋め込み（`<agent-embed>`）。多幕ステージ・数式併置・広い幾何キャンバス等で `> 450px` を要する場合はスタンドアロンアーティファクト（`bg-[var(--background)]`）として出力する。

---

## 1. 4つの基本原則（Core Pillars）

1. **変化表象と累積構築（Compositional Build & MOT Limit）**
   - 装飾目的の動き・無意味な常時ループを排し、構造変化や因果伝播を表す動きだけを採用する（Höffler & Leutner, 2007; Bartram & Ware, 2002）。
   - 複雑な系を初回ビートから一斉稼働させず、**要素単体 → 相互作用ペア（A+B → B+C）→ 全体統合**の順に累積構築する（Lowe & Boucheix APM）。独立軌道で同時移動する主役は原則 **1〜2個（絶対上限 4個）**に制限し、5個以上は **Common Fate** で単一グループ化する（Pylyshyn & Storm, 1988）。
2. **無音Web環境の視覚チャネル調停（Silent-Web Micro-Pacing）**
   - 音声ナレーションを欠くWeb画面では、「字幕・キャプションを読む行為」と「図形の動きを追跡する行為」が単一の視覚チャネル上で衝突（Visual Channel Overload）する（Berney & Bétrancourt, 2016; Mayer Modality）。
   - 読解専用の静止時間（Phase A）とキャンバス主動作（Phase C）を時間軸上で排他分離する。
3. **教育順の物語アークと意味的連続性（Pedagogical Arc & Semantic Continuity）**
   - 冒頭に抽象定義や一般式を置かず、具体例と幾何直観から開始し、定義・公式は最終幕の到達点として提示する（Grant Sanderson / 3Blue1Brown）。
   - `E → I+ → P → R+` のアーク（Amini et al., 2015）、8大視覚物語戦略（Shi et al., 2021）、同一エンティティのみ連続補間する意味的対応（Heer & Robertson, 2007）、空間反転禁止の180°ルール・Eye Trace（Smith, 2012）を厳守する。
4. **決定論的シアター制御とアクセシビリティ（Deterministic Theater & WCAG 2.2）**
   - `setTimeout` の連鎖を禁じ、単一の決定論的状態 `(beatIndex, elapsedMs)` から全ビジュアル属性を純粋計算する `render(state)` で駆動する。
   - **再生/一時停止・1ビート戻し/送り・現在ビート再再生・幕/ビートマーカー付きシークバー・速度変更（`0.5x–2.0x`）・手動ステップ切替・任意予測プロンプト（Responding）・`prefers-reduced-motion` 自動検知＋手動トグル＋直前状態の残像履歴（Trace/History）**を標準装備する。

---

## 2. 無音Web環境におけるマイクロペーシング／タイミング規則

1ビート（単一の主張・因果ステップ）を以下の **5フェーズ排他タイムライン** で設計し、読解とモーション追跡の衝突を完全に防ぐ。

- **Phase A（読解静止 / Reading Dwell）**: キャンバスを完全静止（前ビート最終状態または初期配置）に保ったまま、最大2行以内の極短キャプションを表示する。必要読解時間は文字数 $C$ と言語別読解速度 $R_{\text{CPS}}$ から以下で自動算出する：
  $$T_{\text{read}} = \max\left(T_{\min},\; \min\left(T_{\max},\; \frac{C}{R_{\text{CPS}}}\right)\right)$$
- **Phase B（視線誘導・予備動作 / Cue & Anticipation：`200–400 ms`）**: キャプション静止を維持したまま、非関連要素を `opacity: 0.15–0.25` へディミングし、主役のハイライト点灯・微細な予備動作（Anticipation）で視線を字幕領域からキャンバス焦点へ誘導する。
- **Phase C（主動作 / Primary Motion：単段階 `800–1250 ms`、多段階最大 `2000 ms`）**: キャプションの書き換えを禁止し、単一主題（Staging）の主動作を Cubic Slow-in / Slow-out（`cubic-bezier(0.4, 0, 0.2, 1)` 等）で実行する。因果伝播には Progressive Path キューを動作開始と厳密同期させる。
- **Phase D（定着ホールド / Consolidation Dwell：`1000–2500 ms`）**: モーション完了後、直ちに次へ進まず最終状態を静止保持して内省・記憶統合を促す（Spanjers et al., 2012）。標準ビートは `1000–1500 ms`、重要概念や Peak ビートは `1800–2500 ms` を確保する。
- **Phase E（ビート境界 / Active Pause）**: 最小2フレーム（`>= 33 ms`）の明確な切れ目を設ける。Peak 直前などの重要局面では任意（設定でオフ切替可）の1問2〜3択予測プロンプト（Responding）で一時停止させる。

| 言語区分 | 推奨読解速度 $R_{\text{CPS}}$ | 1行上限・最大行数 | 最小 / 最大表示時間 ($T_{\min} / T_{\max}$) | 運用目安 |
| :--- | :--- | :--- | :--- | :--- |
| **日本語** | `4.0` 全角文字/秒（熟達者向けでも `5.0–6.0` 以下） | 13–16 全角文字/行、最大 2行（1ビート $\le 32$ 文字） | 推奨 `1.0 s`（Netflix規格下限 `0.5 s`）/ 上限 `7.0 s` | 長尺化を防ぐため極力 8–16 文字（`2.0–4.0 s`）へ圧縮する |
| **英語** | `15–17` 文字/秒（上限 `20 CPS` 厳禁） | 37–42 文字/行、最大 2行（1ビート $\le 84$ 文字） | 規格下限 `0.833 s`（5/6秒）/ 上限 `7.0 s` | Netflix 一般目標 `17 CPS` / BBC `160–180 WPM` 準拠 |

- **空間配置ルール**: 1〜3語の単語ラベルは図形直近に配置して視線往復（Split-Attention）を削減し、文単位のナレーション相当キャプションは視界下部の固定位置に統一する。

---

## 3. 必須制作パイプライン（5-Stage Workflow）

いきなりコード生成（Stage 4）を始めず、必ず **Stage 1〜3 の設計仕様を先に確定** させてから実装する。

1. **Stage 1：脚本・ビート分解（Pedagogical Script & Beat Decomposition）**
   - 対象概念を「論理順」ではなく「教育順（具体例 → 要素 → 相互作用ペア → Aha! → 一般化定義）」へ再構成し、`E → I+ → P → R+` の **5幕・6〜10ビート** に分解する（幕配分目安：Establisher 10–15% / Initial-A 20–25% / Initial-B 30–35% / Peak 15–20% / Release 15–20%）。
   - 各ビートに (a) 単一の学習目標、(b) 8大物語戦略タグ（`Emphasis`, `Suspense`, `Comparison`, `Cohering`, `Ellipsis`, `Focalization`, `Concretization`, `Twist`）、(c) 2行以内キャプション、(d) 任意Responding予測（Peak直前など）を確定する。
2. **Stage 2：視覚キャスト・空間設計・カメラ設計（Visual Cast, Spatial Map & Camera Blueprint）**
   - 全エンティティに固定 ID と一貫したセマンティックカラー（背景コンテキスト＝低彩度グレー、焦点＝高コントラスト色、数式項と幾何要素＝同色対応）を割り当てる。
   - ビート間の**オブジェクト対応表（`enter` / `update` / `exit`）**を作成して意味的対応を検証し、180°ルールと Eye Trace を破らない固定座標系およびカメラフレーム（Pan / Zoom 計画）を確定する。
3. **Stage 3：モーション振付とマイクロペーシング設計（Choreography & Micro-Pacing Spec）**
   - 👉 [references/research-and-motion-vocabulary.md](./references/research-and-motion-vocabulary.md) の10種マッピング表と3トレードオフ規則に基づき、各ビートのモーション語彙・イージング（標準は Cubic Slow-in/Slow-out）・ディミング・残像（Trace/History）を選定する。
   - 全ビートの `Phase A / B / C / D / E` 時間（ms）と同時独立稼働数（`<= 4`）を数値テーブルで確定する。
4. **Stage 4：決定論的タイムラインと再生シアターUIの実装（Deterministic Engine & Theater UI）**
   - 👉 [references/implementation-patterns.md](./references/implementation-patterns.md) を参照し、単一状態 `(beatIndex, elapsedMs)` の純粋関数 `render(state)` と再生シアターUI（Play/Pause、1ビート戻し/送り/再再生、幕＆ビート境界シークバー、`0.5x–2.0x` 速度、Auto/Manual切替、`Space`/`←`/`→`/`R` 操作、`prefers-reduced-motion`＋手動トグル、残像表示）を実装する。
5. **Stage 5：出力前 自己監査ゲート（7-Item Self-Audit Gate）**
   - 出力直前に第4節の7項目チェックリストで全ビートとUIコードを監査し、1項目でも違反があれば Stage 3〜4 へ差し戻して修正する。

---

## 4. 出力前 7項目自己監査チェックリスト（Self-Audit Gate）

👉 **各項目に対応するアンチパターン（Gotchas #1–#10）と定量的根拠の詳細は [references/anti-patterns-and-audit.md](./references/anti-patterns-and-audit.md) を参照。**

- [ ] **監査1（無音同期）**: すべてのビートで Phase A（文字数と CPS から算出した読解静止時間）完了前に主要モーションが発火していないか。キャプションは2行・上限文字数以内か。
- [ ] **監査2（Staging と追跡上限）**: 同時に独立移動する注目要素が **4個以下** か（理想 1〜2個、5個以上は Common Fate 化）。非関連要素のディミング（`0.15–0.25`）と単一主題の Staging が保たれているか。
- [ ] **監査3（意味的対応）**: 対応関係のない要素間のモーフィング、Timestep 2D移動の不自然な直交段階化、誇張バウンス（Squash & Stretch）が混入していないか。
- [ ] **監査4（間とイージング）**: 位置・カメラ移動に `linear` が残っていないか（物理的定速フローなど明確な理由がある場合を除く）。全ビート末に `>= 1000 ms`（Peak時は `>= 1800 ms`）の定着ホールドがあるか。
- [ ] **監査5（視覚衛生）**: 背景の常時ループアニメーション、浮遊パーティクル、根拠のないテキスト移動（Coherence違反）がゼロか。
- [ ] **監査6（空間連続性と履歴）**: シーン間で左右・座標配置が反転していないか（180°ルール）。比較が必要なビートで変化前の残像／軌跡（Trace/History）が残っているか。
- [ ] **監査7（制御性とアクセシビリティ）**: 任意のビートへ巻き戻し・シークしても状態が破綻しないか（決定論性）。`prefers-reduced-motion` 自動検知と手動トグルで動きを止めても解説が完全に成立するか。

---

## 5. リファレンス一覧（Progressive Disclosure）

- **[references/research-and-motion-vocabulary.md](./references/research-and-motion-vocabulary.md)**: 5領域の一次文献マスタ一覧・境界条件・演出哲学、5幕アーク（`E → I+ → P → R+`）仕様、解説意図別「モーション語彙・デザイン空間」10パターン対応表、3つの重要トレードオフ判断基準。
- **[references/anti-patterns-and-audit.md](./references/anti-patterns-and-audit.md)**: 定量的エビデンス一覧（メタ分析効果量・CTML・知覚上限・CPS規格）、AIがやりがちな10大アンチパターン（Gotchas #1–#10）と MUST/NEVER 制約集、7項目自己監査ゲートの詳細検証基準。
- **[references/implementation-patterns.md](./references/implementation-patterns.md)**: ゼロ依存 HTML/SVG/Canvas/CSS/JS 実装パターン集（無音CPS自動計算＋決定論的タイムラインエンジン、シアターUI＆キーボード操作、Responding予測チェックポイント、Progressive Path＆ディミング＆残像履歴、`enter/update/exit` 照合＋`viewBox`カメラワーク、`prefers-reduced-motion`フォールバック、`generative_ui` テンプレート＆`themechange`同期）。
