---
name: pr-walkthrough-animation
description: >-
  Design and build animated visual walkthroughs and playback theater Web UIs (HTML/SVG/CSS/JS) that explain Git Pull Requests, branch diffs, and uncommitted code changes for rapid self-comprehension. Combines code-change comprehension (BLUF top-down order, semantic change clustering, surrounding-context verification, risk & AI-pitfall auditing) with choreographed animation principles (silent-web micro-pacing, MOT tracking limit, diagram-to-code focus sync, deterministic timeline controls).
  Use whenever the user asks to explain a PR, git diff, or branch changes through an animated walkthrough or visual movie/theater (e.g., "PRの内容を解説する動画を作って", "このPRをアニメーションで解説して", "ブランチの差分を動きで理解したい", "PRのウォークスルーアニメを作って").
  Do NOT use for general conceptual/math/algorithm animations unrelated to a repository diff (use explanatory-animation), hands-on parameter sandboxes (use interactive-explanation), or interactive comprehension quizzes (use pre-review-quiz).
---

# PR Walkthrough Animation Skill

Git の Pull Request・ブランチ差分・未コミット変更を対象に、**「生 diff を上から読む苦痛」を排し、変更の全体像・Before/After の実行フロー・核心コード抜粋・隠れたリスクを時間軸のアニメーションで一気に頭へ入れる**ための解説シアター Web UI 設計・実装スキル。

- **想定ユースケース**：自分がレビューする PR、AI に実装させた PR、規模の大きいブランチ差分の構造と副作用を短時間で正確に把握する（理解の抜けをテストしたい場合は、本スキル視聴後に `pre-review-quiz` を併用する）。
- **2層分離アーキテクチャ（将来の MP4 / Remotion / 音声対応を見据えた設計）**：
  - **Layer 1（PR解析 ＆ 変更ストーリーボード設計・出力非依存）**：PR差分取得・周辺ファイル裏取り・意味的クラスタリング・BLUF 5幕ストーリーボード JSON の策定。
  - **Layer 2（レンダリング出力・現在は HTML/SVG 再生シアター）**：Layer 1 のストーリーボードを入力として、無音Web環境向けの決定論的 HTML/SVG 再生シアターを描画する（将来 Remotion / MP4＋TTS レンダラへ差し替え可能）。

> [!IMPORTANT]
> **Antigravity（`generative_ui`）環境で HTML/SVG 出力する際の必須制約**
> 1. **外部CDN禁止（CSP制約）**: 許可された Tailwind スクリプト（`https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js`）以外の外部ライブラリ（GSAP / Shiki / D3 等）は読み込めない。タイムライン・コード差分ハイライト・SVGフローアニメーションはすべて**ゼロ依存のインライン HTML/SVG/CSS/JS**で実装する。
> 2. **テーマ変数とライト/ダーク両対応**: `bg-[var(--card)]`, `text-[var(--foreground)]`, `text-[var(--muted-foreground)]`, `border-[var(--border)]`, `--primary` 等のセマンティックトークンを用い、`:root` への独自色フォールバックやハードコード色（`bg-slate-900`, `text-white` 等）を避ける。最小フォントサイズは `12px`（`text-xs`）以上を厳守する。
> 3. **配置の判断（スタンドアロン優先）**: PRウォークスルーは左（実行フローSVG）＋右（核心コード8〜12行）の2ペイン＋操作バーを要するため、**原則スタンドアロンアーティファクト（`bg-[var(--background)]`）**として出力する（`UserFacing: true`）。超小型PRで高さ `<= 450px` に収まる場合のみインライン埋め込み（`<agent-embed>`、`h-screen`/`100vh` 禁止）を検討する。

---

## 1. 4つの基本原則（Core Pillars）

1. **結論先行・実行順のトップダウン構成（BLUF & Dependency Order）**
   - 抽象概念の解説（3Blue1Brown 型の焦らし・ミステリー順）とは異なり、PR 解説では**冒頭ビートで結論（目的・変更点・影響範囲・不変条件）を即座に提示する（BLUF）**。
   - Git のファイル名アルファベット順に並べず、**実行経路・依存関係のストーリー順（Entry Point → コアロジック → データ/副作用 → テスト）**へ再構成する（Baum et al., 2019; Barnett et al., 2015）。
2. **生 diff 丸映しの禁止と「図 × 抜粋コード」の空間統合（Diagram-Code Sync）**
   - 画面いっぱいの unified diff は文字が小さく読めないため全面禁止する。
   - **左：抽象アーキテクチャ／実行フロー SVG（Before → After の経路変化）** と **右：核心コード抜粋（1画面最大 8〜12行、変更箇所の Magic Move 風ハイライト・周辺ディミング）** を並置し、共通 `data-key` による双方向ハイライトと **`path/to/file.ext:L42-L51` の行番号バッジ** を常時表示する。
3. **diff 単体推測の禁止とリスク・盲点の明示（Grounded Verification & Risk幕）**
   - diff 断片だけから挙動を推測せず、呼び出し元・型定義・テスト・スキーマ等の周辺 1〜4ファイルを必ず実読して裏取りする。
   - 正常系だけでなく、**第4幕を「境界条件・高リスク箇所・AI生成コード特有の落とし穴」専用幕**として必ず確保し、見落としを防ぐ。
4. **無音Webマイクロペーシングと決定論的シアター制御（Silent-Web Theater）**
   - `explanatory-animation` の実証ルールを継承し、**Phase A（読解静止・日本語 `4.0 CPS` / 英語 `17 CPS` 自動計算）→ Phase B（視線誘導・ディミング `200–400 ms`）→ Phase C（主動作 `800–1250 ms`・MOT上限 `<= 4`）→ Phase D（定着ホールド `1000–2500 ms`）→ Phase E（ビート境界）** の排他タイムラインで「読む」と「見る」の衝突を防ぐ。
   - `setTimeout` 連鎖を禁じ、単一時刻状態 `tMs` から描画する純粋関数 `render(state)` と、再生/一時停止・1ビート戻し/送り・再再生・幕マーカー付きシーク・速度変更（`0.5x–2.0x`）・手動ステップ切替・`prefers-reduced-motion` 対応を標準実装する。

---

## 2. トップダウン 5幕構成（BLUF Walkthrough Arc）

PR の規模に応じて **5幕・6〜9ビート**（全体再生目安 60〜150秒）に分解する。軽微・自明な差分（20行未満の typo/コメント/フォーマット修正のみ）の場合は、無理にフルアニメ化せず「軽微なためテキスト要約で十分か、3ビート簡易版にするか」を先に1行確認する。

| 幕 | 尺目安（ビート数） | 認知的役割 | 必須要素 |
| :--- | :--- | :--- | :--- |
| **第1幕：TL;DR & Blast Radius** | 10–15%（1ビート） | 結論と影響範囲の地図（BLUF） | 変更目的（Why）1文、変更対象モジュール俯瞰図、**変えてはいけない不変条件（Invariant）** の明示 |
| **第2幕：Before / Context** | 15–20%（1–2ビート） | 変更前の挙動と課題の共有 | 変更前の実行フロー・バグ再現経路・既存拡張ポイント（この状態を後続幕の残像基準にする） |
| **第3幕：Core Flow & Code Focus** | 35–40%（2–4ビート） | 実行順の Before → After 解説 | 依存/実行順に 1責務＝1ビートで展開。左フロー図の Progressive Path 変化と右コード抜粋（$\le 12$行）を同期 |
| **第4幕：Edge Cases & Risk Audit** | 15–20%（1–2ビート） | 自分の見落とし・副作用の点検 | 高リスク要素（DB/認可/非同期/例外処理/新規依存/テスト期待値変更）と異常系パスを赤/アンバーで強調 |
| **第5幕：Test Coverage & Summary** | 10–15%（1ビート） | 検証範囲の把握と再確認ハブ | 追加/変更テストのカバー範囲、変更ファイル＋行番号サマリー一覧、任意ビートへ即ジャンプできる静止俯瞰状態 |

---

## 3. 必須制作パイプライン（5-Stage Workflow）

いきなり HTML コード生成（Stage 4）を始めず、必ず **Layer 1（Stage 1〜2）→ Layer 2（Stage 3〜5）** の順で進める。

### Layer 1：PR解析 ＆ 出力非依存ストーリーボード設計

1. **Stage 1：PR / ブランチ差分の取得・裏取り・リスク診断**
   - 👉 [references/pr-analysis-and-storyboard.md](./references/pr-analysis-and-storyboard.md) に従い、PR（`gh pr view` / `gh pr diff`）またはローカルブランチ差分（`git diff <base>...HEAD`）を取得し、ノイズ差分を除外する。
   - 変更の呼び出し元・関連テスト・スキーマ・設計文書（1〜4ファイル）を実際に読み込んで裏取りし、**PRタイプ（Bugfix / Feature / Refactor / Architecture / UI）**と**高リスク・AI生成の落とし穴**を特定する。
2. **Stage 2：意味的クラスタリング ＆ ストーリーボード仕様確定**
   - 変更をファイル名順ではなく**実行順・依存順**にクラスタリングし、第1幕〜第5幕（6〜9ビート）の**出力非依存ストーリーボード構造**（各ビートの `act`, `focusFiles`, `diagramState`, `codeSnippet`, `riskTag`, `caption`）を確定する。
   - 各ビートのキャプションは **最大2行（日本語 $\le 32$ 全角文字、理想 10〜20文字／英語 $\le 84$ 文字）** に圧縮する。

### Layer 2：ビジュアル振付 ＆ 再生シアターUI実装

3. **Stage 3：PRタイプ別ビジュアル設計とマイクロペーシング確定**
   - 👉 [references/code-visual-patterns.md](./references/code-visual-patterns.md) を参照し、PRタイプに応じた図解パターン、各ビートの `enter` / `update` / `exit` オブジェクト対応表、コード抜粋（$\le 12$行）、`data-key` マッピング、Phase A〜E の時間（ms）と同時稼働数（`<= 4`）を確定する。
4. **Stage 4：決定論的 2ペイン再生シアター HTML/SVG の実装**
   - 👉 [references/theater-engine-patterns.md](./references/theater-engine-patterns.md) を参照し、ゼロ依存 HTML/SVG/CSS/JS で2ペイン再生シアター（左：実行フローSVG＋Before残像、右：抜粋コード＋`file:line` バッジ＋Before/Afterトグル、下部：固定キャプション＋操作バー）を実装する。
5. **Stage 5：出力前 8項目自己監査ゲート（Self-Audit Gate）**
   - 出力直前に第4節の8項目チェックリストを全件検証し、1項目でも違反があれば修正してから提示する。

---

## 4. 出力前 8項目自己監査チェックリスト（Self-Audit Gate）

👉 **各項目に対応するPR解説特有のアンチパターン（Gotchas #1–#8）と修正基準の詳細は [references/code-visual-patterns.md](./references/code-visual-patterns.md) を参照。**

- [ ] **監査1（BLUF と実行順）**: 第1幕で結論（Why / What / 影響範囲・不変条件）を先に示しているか？ 第3幕はファイル名アルファベット順ではなく実行経路・依存順になっているか？
- [ ] **監査2（裏取りと根拠の正確性）**: diff 単体の推測ではなく周辺ファイルを実読したか？ すべてのコード抜粋に正確な `ファイルパス:行番号` バッジが付いており、実コードと一致しているか？
- [ ] **監査3（生 diff 禁止と抜粋上限）**: 1ビートあたりの表示コードが **12行以下** に絞られ、変更・注目行以外がディミングされているか？ 巨大な unified diff を丸映ししていないか？
- [ ] **監査4（リスク・異常系の明示）**: 第4幕に境界条件・副作用・高リスク要素（または AI 生成コードの落とし穴）の検証ビートが含まれているか？（該当リスクゼロの純粋リファクタでも不変条件の検証を置いているか？）
- [ ] **監査5（無音同期と字幕制約）**: 全ビートで Phase A（文字数と日本語 `4 CPS` / 英語 `17 CPS` から算出した読解静止時間）完了前に主要モーションが発火していないか？ キャプションは最大2行・上限文字数以内か？
- [ ] **監査6（Staging・追跡上限・180°ルール）**: 同時独立移動が **4個以下**（理想 1〜2個）か？ 非関連ノードのディミング（`0.15–0.25`）があり、Before/After 間でノード配置が左右反転していないか？
- [ ] **監査7（間・イージング・残像）**: 位置・カメラ移動に `linear` が残っていないか？ 全ビート末に `>= 1000 ms`（重要ビート `>= 1800 ms`）の定着ホールドがあり、Before の状態が残像（Trace/History）として比較可能か？
- [ ] **監査8（決定論制御とアクセシビリティ）**: 任意のビートへシーク・巻き戻ししても図・コード・行番号バッジの同期が崩れないか？ `prefers-reduced-motion` 自動検知＋手動トグルで動きを止めても解説が完全に成立するか？

---

## 5. リファレンス一覧（Progressive Disclosure）

- **[references/pr-analysis-and-storyboard.md](./references/pr-analysis-and-storyboard.md)**: 【Layer 1】PR/ブランチ差分取得コマンド、ノイズ除外・周辺ファイル裏取り規則、高リスク＆AI生成コード落とし穴検知、PRタイプ5分類、意味的クラスタリング手順、将来の MP4/Remotion 化でも再利用できる出力非依存ストーリーボード JSON スキーマ。
- **[references/code-visual-patterns.md](./references/code-visual-patterns.md)**: 【Layer 2】PRタイプ別ビジュアル演出テンプレート、図解×コード抜粋（$\le 12$行）の空間統合ルール、Magic Move 風差分ハイライト規約、PR解説アニメ特有の8大アンチパターン（Gotchas #1–#8）と MUST/NEVER 制約。
- **[references/theater-engine-patterns.md](./references/theater-engine-patterns.md)**: 【Layer 2】ゼロ依存 HTML/SVG/CSS/JS の2ペイン再生シアター実装パターン（CPS自動算出・決定論的タイムラインエンジン、SVGフロー×抜粋コード×`file:line` バッジ同期、`data-key` 双方向ハイライト、Before残像切替、`prefers-reduced-motion` 対応、`generative_ui` テンプレート）。
