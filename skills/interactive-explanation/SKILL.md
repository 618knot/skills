---
name: interactive-explanation
description: >-
  Design and build hands-on interactive diagrams, Explorable Explanations, and parameter-exploration laboratories grounded in HCI, Information Visualization, and Cognitive Load Theory (Bret Victor, Ben Shneiderman, Edward Tufte, Barbara Tversky, John Sweller, Nicky Case, Bartosz Ciechanowski, Amit Patel).
  Use when the user wants a reader-driven sandbox, static-first small multiples, direct manipulation handles, sliders/scrubbable numbers, or interactive simulations to test hypotheses and explore multi-variable trade-offs or edge cases (e.g., "いじって理解できる図解", "パラメータを変えて試せるシミュレータ", "Explorable Explanation").
  Do NOT use when the user asks for time-based narrative motion, choreographed playback/step-through animations, 3Blue1Brown/Manim-style visual storytelling, or Data Videos; use explanatory-animation instead.
---

# Interactive Explanation & Diagram Design Skill

複雑な概念・アルゴリズム・数理モデル・物理/工学システム・多変数トレードオフを解説する際、「何でもアニメーションや多変数サンドボックスにする」という素朴なアプローチを排し、HCI・情報可視化・認知負荷理論（CLT）の一次文献に基づく**メンタルモデル構築を最大化するインタラクティブ図解・UI**を設計・実装するためのスキル。

> [!IMPORTANT]
> Antigravity環境でインラインまたはスタンドアロンのHTMLウィジェットとして出力する場合は、必ず `generative_ui` スキルのテーマ変数規約（`bg-[var(--card)]`, `text-[var(--foreground)]`, Tailwind script等）を併用すること。

---

## 1. 3つの基本原則（Core Pillars）

1. **表現のトリアージ（Static-First & Small Multiples）**
   - 受動的なアニメーションや覗き穴UI（Peephole UI：ホバーやドロップダウンで1件ずつしか見せないUI）は、**一過性情報効果（Transient Information Effect）**と**把握可能性の原則（Apprehension Principle）違反**を引き起こし、分析速度と正答率を有意に低下させる（Robertson et al., 2008; Tversky et al., 2002; Sweller, 2011）。
   - **Static-First**: 1回もクリック・ホバーしなくても、静的な初期状態だけで全体比較や主要トレンドが一目で読み取れる表現（**Small Multiples** または **全時間軌跡プロット**）をデフォルトの基盤に据える（Victor, 2011; Tufte, 1983）。
2. **直接操作と空間的統合（Direct Manipulation & Zero Split-Attention）**
   - 描画キャンバスから離れた「操作パネル（スライダー群）」や「独立した凡例ボックス（Legend）」は**注意分割効果（Split-Attention Effect）**を生む（Chandler & Sweller, 1992）。
   - 幾何オブジェクト（制御点・壁・矢印・プローブ）自体をキャンバス上で直接ドラッグさせ（Shneiderman, 1983）、本文テキスト・数式/コード・図解要素を**意味的色分け（Semantic Color-Coding）**と `data-key` による**双方向ホバーハイライト**で空間統合する（Patel, 2021）。
3. **抽象化の梯子と段階的スキャフォールディング（Ladder of Abstraction & Scaffolding）**
   - 具体状態（Rung 0）と、時間・パラメータを畳み込んだ抽象プロット（Rung 1–3）を並置し、抽象グラフ上のホバー/ドラッグで具体状態へ即座に降りる（**Stepping Up & Down**）連動回路を実装する（Victor, 2011）。
   - 要素間相互作用（Element Interactivity）が高いシステムは、最初から全変数を動かせるサンドボックスを与えず、**単一要素の分離操作（Isolated Elements）→ 要素統合（Interacting Elements / Sandbox）** の順で段階的に開放する（Pollock, Chandler, & Sweller, 2002; Case, 2017）。

---

## 2. 必須設計パイプライン（5-Step Workflow）

インタラクティブ図解を生成する際は、必ず以下の5ステップの順序で設計・実装を行うこと。

### Step 1: 認知ゴールの分解と表現トリアージ（Do & Show & Tell）

説明対象から**単一の核心的因果命題（Cause → Effect）**を特定し、メディアの役割を配分する（Nicky Case, 2017）：
- **Tell（テキスト）**: 抽象概念の定義・文脈の導入・問いの提示
- **Show（静的図解 / Small Multiples）**: 全体像・複数カテゴリの横断比較・時間軌跡の一覧
- **Do（インタラクティブ操作）**: 因果関係の仮説検証・パラメータ感度分析・境界条件の探索

#### 表現モード選択マトリクス（Triage Rules）

| 認知ゴール・概念の性質 | 選択すべき表現モード（MUST） | 禁止される表現（NEVER） |
| :--- | :--- | :--- |
| **複数カテゴリ・アルゴリズム・離散フェーズ（3〜8段階）の比較** | **静的 Small Multiples**（または共有入力に連動する並列 Small Multiples） | 単一画面の連続アニメーション／ドロップダウン切替（覗き穴UI） |
| **時間経過に伴う1〜2変数の軌跡・収束・振動の全体把握** | **静的軌跡プロット（Rung 1）＋ ホバーによる具体姿勢（Rung 0）の重畳表示** | 再生・一時停止ボタンだけの実時間アニメーション |
| **連続的な物理過程・数理補間・3D機構の微細な変化様態の理解** | **単一変数スライダー（時間または進行度 $t \in [0,1]$）によるスクラブ操作** | 自動ループ再生のみのアニメーション／数値テキスト入力欄 |
| **離散アルゴリズム（探索・ソート等）のステップ実行と状態遷移** | **全ステップ展開図 または タイムラインスクラブ ＋ コード/状態変数の同期表示** | 入出力だけのブラックボックス表示／高速自動アニメーション |
| **2次元平面上の幾何学的関係・経路・制御点の影響範囲の把握** | **キャンバス上の直接操作（点・壁・矢印・プローブの直接ドラッグ）** | キャンバス外に分離された X/Y 座標スライダー群 |
| **高要素間相互作用（3変数以上が絡むシステム）の法則理解** | **段階的スキャフォールディング（単一変数の分離操作 → 最終段で Sandbox 開放）** | 冒頭からの全パラメータ開放型サンドボックス |
| **統計グラフの軸変更・集計単位変更に伴う同一要素の追跡** | **短時間（1.0〜1.25秒）・段階的（Staged）なアニメーション遷移** | 瞬時のジャンプカット／無関係データ間のモーフィング |

#### 変数選定の4規則（Active vs. Fixed Variables）

1. **1命題1独立変数の抽出**: 証明したい因果命題の独立変数（原因）のみを操作開放し、他の環境変数は命題が最も鮮明に現れる値に固定（Lock）する。
2. **意味的直観性（Semantic Directness）への変換**: 内部数式の生の係数ではなく、ユーザーが空間的・物理的直観と結びつけられる量（例：制御点の位置、迎え角、伝達ミス率）を操作ハンドルにし、内部パラメータはそこから自動導出（Derive）する。
3. **不変条件（Invariants）の保護**: アルゴリズムが破綻する不正入力領域は `.clamped(lo, hi)` 等で制限する。ただし「なぜその状態が物理的に不可能か（例：流線の壁面貫通、トルク0の死点）」を学習させるステップに限り、赤色警告表示とともに開放する。
4. **時間変数 $t$ の自己遮蔽（Occlusion）判定**: 軌跡が自己遮蔽しない1D/2D運動は、時間を空間軸または軌跡曲線（Rung 1）として静的に展開し、スライダーは別のシステム変数に割り当てる。3D機構や流体場など全時間を重ねると遮蔽（Occlusion）が生じる場合にのみ、時間をスクラブスライダーに割り当てる。

---

### Step 2: 概念構造別アーキテクチャと「抽象化の梯子」設計

対象トピックの概念構造に応じ、具体的な操作パターン（How）と視覚フィードバック（What）を選択する。
👉 **10種類の概念構造別マッピングの詳細は [references/topic-patterns-and-triage.md](./references/topic-patterns-and-triage.md) を参照。**

#### 抽象化の梯子（Ladder of Abstraction）の双方向実装ルール
- **Rung 0（具体インスタンス）**: 特定時刻 $t$・特定パラメータ値における具体的オブジェクトの状態・姿勢を描画する。
- **Rung 1（時間に対する抽象化）**: 全時間ステップを畳み込んだ軌跡曲線（Trajectory）やタイムラインを静的に描く。
- **Rung 2–3（パラメータに対する抽象化）**: パラメータ全体を横軸にとった要約指標グラフや2Dヒートマップ（位相空間）を並置する。
- **MUST（Stepping Back Down）**: Rung 1〜3 の抽象グラフを単独で置いてはならない。必ず**抽象グラフ上のホバー／ドラッグによって対応する Rung 0 の具体状態や Rung 1 の個別軌跡をリアルタイムに重畳・スライス表示する双方向回路**を実装する。

---

### Step 3: 段階的スキャフォールディングと認知フック設計

複雑な概念（要素間相互作用が高いテーマ）を解説する際は、以下の4段階パイプライン（Martini Glass 構造 / Interactive Slideshow 構造）で構成する：

1. **Stage 1: Hook & 事前予測 / 破綻トイモデル（Cognitive Gate & Pretraining）**
   - **Pretraining**: 複雑システムを動かす前に、構成要素の名称と単体特性を意味的色分けで導入する（Mayer & Moreno, 2003）。
   - **Place Your Bets / You Draw It**: 反直観的な結果やトレンドを見せる前に、「どちらが勝つか？」「どんな曲線になるか？」をユーザーに予測選択・描画させてコミットさせた後、正解シミュレーションを重ねて提示する（Case, 2018; Hohman et al., 2020）。
   - **Broken Toy Model**: なぜその部品・項が必要かを示すため、まず「その要素を欠いた単純モデル（例：脱進機のない時計、ヒューリスティック項のない探索）」を動かしてどう破綻するかを体験させる（Ciechanowski; Patel）。
2. **Stage 2: 孤立要素の分離操作（Isolated Elements）**
   - 他変数をロックし、**操作可能なスライダーを1つ（最大2つ）に制限**して単一の因果関係を確認させる（Pollock et al., 2002）。
   - 自由操作スライダーの直近には、必ず**「典型例」「相転移の閾値」「破綻するエッジケース」へワンクリックで飛べるプリセットボタン（Preset Jumpers）**を2〜3個配置する。
3. **Stage 3: 要素結合と並列比較（Interacting Elements / Linked Small Multiples）**
   - 2〜3要素の相互作用を開放する、または同一の入力操作（マップ編集やスライダー）を共有する複数アルゴリズム（例：BFS / Dijkstra / A*）を **並列 Small Multiples** で同時更新して比較させる。
4. **Stage 4: 足場解除と自由探索（Open Sandbox / Fading Scaffolding）**
   - 個別の部分スキーマが形成された最終セクションでのみ、全パラメータを自由に同時操作できる Sandbox Mode を開放する（熟達度逆転効果 Expertise Reversal Effect の回避）。

---

### Step 4: 直接操作・空間統合・視覚シグナリング実装

UI・コード実装時は以下の5つの技術規則を厳守する。
👉 **そのまま使える HTML/JS/SVG/Canvas 実装スニペットは [references/implementation-patterns.md](./references/implementation-patterns.md) を参照。**

1. **Canvas上の直接操作とインライン数値スクラブ**
   - 2D座標・制御点・壁・プローブは、外部スライダーではなくキャンバス上のハンドル（大きめのヒット領域 `r >= 12px`、ホバー時にカーソルとリングを強調）で直接ドラッグさせる。
   - 文中の前提数値で感度分析を行わせる場合は、テキスト内の数値を直接左右ドラッグできる **Scrubbable Numbers（Tangle風リアクティブ変数）** を用いる。
2. **凡例ボックスの廃止と双方向ホバーハイライト（`data-key` 結合）**
   - 独立した凡例（Legend）は作らない。図解要素の直近に直接ラベルを配置し、本文中にはインラインSVGまたは色付きピル（Semantic Color-Coding）を埋め込む。
   - 本文の用語・数式/コードの変数・図解のSVG要素に共通の `data-key="concept-id"` 属性を付与し、`pointerover` / `pointerout` で全ビューの該当要素が同時にハイライトされるように結合する。
3. **視覚的シグナリング（Signaling）と色彩抑制（Color Restraint）**
   - 同時に多数の鮮やかな色を使わない。現在のステップで説明している主役の因果要素だけに高彩度の意味的カラーを割り当て、補助グリッド・背景構造・非注目要素は低彩度/グレーへ後退させる（Layering & Separation / Weeding）。
   - コードを併記する場合は、一般的な構文ハイライト（予約語の色分け）をやめ、**図解上の状態色とコード内の変数・処理行の色を一致**させる。
4. **決定論的連続性（Visual Continuity）の保証**
   - スライダーやハンドルをわずかに動かした際、乱数やタイブレーク順序の揺らぎで出力が激しくジャンプ（Flicker）することを厳禁とする。乱数シードとタイブレーク規則を固定し、入力 $x$ に対して出力 $f(x)$ が決定論的かつ滑らかに変化するように実装する。
5. **ペース制御（Self-Pacing）とスクロールジャック禁止**
   - ページ全体のスクロールを乗っ取る Scrollytelling は避け、静的な解説文の中に自己完結したインタラクティブ・モジュール（**Islands of Interactivity**）を配置するか、読者が明示的に「次へ / ステップ送り」を押す **Step-based Slideshow** とする。

---

### Step 5: 10大アンチパターン（Gotchas）自己監査チェックリスト

コードや図解を出力する直前に、以下の10項目すべてを満たしているか自己監査を行うこと。1つでも違反がある場合は設計を修正してから出力する。
👉 **各アンチパターンの認知科学的根拠と修正パターンの詳細は [references/anti-patterns-and-audit.md](./references/anti-patterns-and-audit.md) を参照。**

- [ ] **1. 冒頭サンドボックスの禁止**: 最初のビューに3個以上のスライダーを並べていないか？（導入〜中盤は1ビュー1〜2変数に制限し、多変数Sandboxは最終段のみか？）
- [ ] **2. 注意分割（Split-Attention）の排除**: 離れた操作パネルや独立した凡例ボックスを作っていないか？（直接ドラッグ・直近ラベル・インライン凡例・`data-key` 双方向ハイライトを使っているか？）
- [ ] **3. 再生専用アニメーションの禁止**: 「Play / Pause」だけの受動的アニメーションになっていないか？（タイムスクラブ・スライダー、コマ送り、または Rung 1 静的軌跡プロット＋ホバー重畳になっているか？）
- [ ] **4. 覗き穴UI（Peephole UI）の禁止**: ホバーやドロップダウン操作をしないと初期状態でデータ全体が見えない設計になっていないか？（Static-First で初期状態から全体比較が可能か？）
- [ ] **5. エッジケース・プリセットの提供**: 自由操作スライダーの近くに「典型例」「閾値（相転移点）」「破綻例」へ誘導するプリセットボタンや数値ガイドが2〜3個あるか？
- [ ] **6. 事前予測ゲート（Place Your Bets）**: 反直観的な結果やパラドックスを説明する際、いきなり正解を見せず、ユーザーに事前予測（選択または描画）させるステップがあるか？
- [ ] **7. スクロールジャックの排除**: スクロール連動の強制画面切替を避け、ユーザー自身がペースを支配できる Islands of Interactivity またはステップボタン制御になっているか？
- [ ] **8. 非決定論的チラつき（Flicker）の防止**: 微小なドラッグ操作に対して乱数やタイブレークで出力が不連続にジャンプしないよう、シード固定・タイブレーク安定化・`.clamped()` 制約が入っているか？
- [ ] **9. 意味的恒常性とChartjunk排除**: 無関係なデータ間でモーフィングを行っていないか？不要な3D表現や装飾的枠線を排し、本質的なスキーマ表現に絞っているか？
- [ ] **10. 複数表現の同時連動（Multiple Linked Views）**: 単一表現（数式だけ、物理アニメだけ）に偏らず、具体ビュー（Rung 0）・抽象グラフ（Rung 1–2）・数式/コード状態（Symbolic）がリアルタイムに連動（"dance together"）しているか？

---

## 3. リファレンス一覧（Progressive Disclosure）

詳細な設計判断や実装コードが必要な場合は、以下のリファレンスファイルを読み込むこと：

- **[references/topic-patterns-and-triage.md](./references/topic-patterns-and-triage.md)**: 表現トリアージの詳細基準、10種類の対象トピック構造×操作パターン×視覚フィードバック完全対応表、および一次文献（Victor, Shneiderman, Tufte, Tversky, Sweller, Case, Ciechanowski, Patel）の核心理論。
- **[references/anti-patterns-and-audit.md](./references/anti-patterns-and-audit.md)**: AIが陥りやすい10大アンチパターン（Gotchas）の認知科学的敗因、定量的エビデンス（Robertson 2008, Mayer & Moreno 2003）、および具体的なリファクタリング規則。
- **[references/implementation-patterns.md](./references/implementation-patterns.md)**: インタラクティブ図解を実装するための再利用可能な HTML/CSS/JS 設計パターン集（`data-key` 双方向ハイライト、Scrubbable Numbers、Canvas+SVG直接操作ハンドル、Rung 0↔1 抽象化の梯子連動、Place Your Bets 予測ゲート）。
