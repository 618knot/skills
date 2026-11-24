---
name: pr-walkthrough-animation
description: >-
  Design and build animated visual walkthroughs that explain Git Pull Requests, branch diffs, and uncommitted code changes either as a silent interactive playback theater Web UI (Mode A, default: HTML/SVG/CSS/JS) or as a narrated MP4/WebM walkthrough video with WebVTT subtitles (Mode B: Audio-First Remotion or Playwright+FFmpeg). Grounded in code-change comprehension research (Bacchelli & Bird, Tao, Barnett, Baum), multimedia learning theory (Mayer CTML), and choreographed animation principles.
  Use whenever the user asks to explain a PR, git diff, or branch changes through an animated walkthrough, movie, or narrated video (e.g., "PRの内容を解説する動画を作って", "このPRをアニメーションで解説して", "音声付きPR解説動画を作って", "MP4でPR解説を作って", "ブランチの差分を動きで理解したい").
  Do NOT use for general conceptual/math/algorithm animations unrelated to a repository diff (use explanatory-animation), hands-on parameter sandboxes (use interactive-explanation), or interactive comprehension quizzes (use pre-review-quiz).
---

# PR Walkthrough Animation Skill

Git の Pull Request・ブランチ差分・未コミット変更を自律解析し、**「生 diff の丸映し」を排して、変更理由（Why）・構造変化・核心コード・破壊リスク／類似箇所への波及を短時間で頭に入れる解説アニメーション**を設計・生成するスキル。

- **出力モード選択（Mode A デフォルト / Mode B 拡張）**：
  - **Mode A（無音 HTML/SVG 再生シアター・デフォルト）**: チャット内プレビューやブラウザ即時確認向け。`generative_ui` 環境で外部CDNなし（許可 Tailwind のみ）で即動作。
  - **Mode B（音声ナレーション付き MP4/WebM＋WebVTT 動画）**: ユーザーが「MP4」「動画ファイル」「音声付き」「Remotion」「GitHub PR に貼る動画」等を明示した際に選択。Audio-First で確定フレームをレンダリングする。
- **2層分離アーキテクチャ**：**Layer 1（PR解析・意味的クラスタリング・4ブロック中間ストーリーボード JSON）** を共通土台とし、**Layer 2-A（無音シアター）** または **Layer 2-B（Audio-First 動画）** を独立出力する。

> [!IMPORTANT]
> **Mode A（Antigravity `generative_ui`）出力時の必須制約**
> 1. **外部CDN禁止（CSP制約）**: 許可された Tailwind スクリプト（`https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js`）以外は読み込めない。すべてゼロ依存の HTML/SVG/CSS/JS で実装する。
> 2. **テーマ変数と視認性**: `bg-[var(--card)]`, `text-[var(--foreground)]`, `text-[var(--muted-foreground)]`, `border-[var(--border)]`, `--primary` 等を使い、`:root` への独自色フォールバックやハードコード色を避ける。最小フォントは `12px`（`text-xs`）以上。
> 3. **配置**: 原則スタンドアロンアーティファクト（`bg-[var(--background)]`, `UserFacing: true`）として出力する。超小型PRで高さ `<= 450px` に収まる場合のみ `<agent-embed>`（`h-screen`/`100vh` 禁止）を検討する。

---

## 1. 4つの基本原則（Core Pillars）

1. **BLUF-then-Causal-Narrative と複合変更の分解**
   - 冒頭 `10–15秒` で変更理由（Tao I-1）と破壊リスク・影響範囲（I-9）を BLUF で即答し、本編は「課題 → 設計 → コード変形 → リスク検証」の因果ナラティブへ接続する（Wise et al., 2009; Emde et al., 2016）。
   - 約42%のPRは複合変更を含むため（Barnett et al., 2015）、lockfile 等のノイズを除き**最大3関心事クラスタ**へ事前分解する（Dias et al., 2015）。
2. **依存順配列＋同一画面同時表示（Baum Principle 1, 5, 6）**
   - Git のファイル名アルファベット順を厳禁とし、呼び出し・データフロー依存順に並べ替えて順序規則を冒頭明示する（Baum et al., 2017）。ただし順序変更単独の効果には限界があるため（Baum et al., 2019 の留保）、**関連2箇所や Before/After を同一フレームに同時表示（Principle 5）**し、生 diff ではなく抜粋コード（Mode A $\le 12$行、Mode B 10–15行推奨・上限18行・1行 $\le 80$文字）で示す。
3. **diff 単体推測禁止と「Why・リスク・類似箇所（I-10）」の開示**
   - 周辺 1〜4ファイルを必ず実読して裏取りする。構文の逐語朗読（`3行目でxを+1`）を禁じ、**なぜその設計を選び別案を採らなかったか**（Bacchelli & Bird, 2013; MacLeod et al., 2015）と、高リスク・AI生成落とし穴・**類似箇所への一貫性（Tao I-10）**を必ず独立フェーズで扱う。
4. **出力モードに応じた認知チャネル最適化**
   - **Mode A（無音）**: 視覚チャネル競合を防ぐ 5フェーズ排他タイムライン（Phase A 日本語 `4.0 CPS`/英語 `17 CPS` 読解静止 → B 誘導 `200–400 ms` → C 主動作 `800–1250 ms`・MOT `<= 4` → D 定着 `1000–2500 ms` → E 境界）＋決定論的 `render(state)`。
   - **Mode B（音声付き）**: 聴覚（Why）と視覚（What/Where）の時間的近接並列（$d=1.31$）。音声先行 `45 ms` 厳禁（視覚 `50–100 ms` 先行: ITU-R BT.1359-1）、長文テロップ焼き込み禁止（2–3語ラベル＋分離 WebVTT）、Audio-First（TTS先生成→実尺からフレーム逆算）、標準尺 `60–180秒`（厳格上限 `300秒`: Guo et al., 2014）、GitHub 互換 `H.264 yuv420p`・`9.5 MB` 以下。

---

## 2. 6フェーズ標準構成（BLUF ＋ 因果ナラティブ・標準 60–180秒 / 上限 300秒）

軽微・自明な差分（20行未満で分岐・状態変更なし）はフル構成にせず「テキスト要約でよいか・3ビート簡易版にするか」を先に1行確認する。

| フェーズ | 尺目安 | 構成上の役割 | コード行数上限（Mode B / Mode A） |
| :--- | :--- | :--- | :--- |
| **① TL;DR・影響範囲（BLUF）** | 10–15秒 | 目的（Why）・結論・影響マップ・不変条件・リスクバッジの即時提示（ミュート冒頭完結） | 0行（要約カード最大3項目） |
| **② Before 文脈** | 15–25秒 | 既存構造の制約・バグ再現パス・課題の共有（後続フェーズの残像基準） | 原則 0行（必要時 5–8行） |
| **③ コア変更フロー（抽象図）** | 20–40秒 | 変更前後のアーキテクチャ／データフロー変形（新規強調ノード `<= 4` 個） | 0行（2–3語ラベル近接配置） |
| **④ コード抜粋変形（Focus+Context）** | 30–70秒 | 依存順に 1クラスタ/ビートで Before→After 変形・`file:line` バッジ・関連2箇所分割 | Mode B: 10–15行（上限18行）／Mode A: $\le 12$行 |
| **⑤ エッジケース・リスク・類似箇所（I-9/I-10）** | 15–30秒 | DB/認可/非同期/テスト書換/AI生成落とし穴と類似箇所への波及確認 | 6–10行上限＋リスク種別バッジ |
| **⑥ テスト・検証・まとめ** | 10–20秒 | テスト網羅・UI Before/After・確認してほしい論点・末尾 `1.5–2.0秒` 静止ホールド | 核心アサーション 5–8行 または 表最大4行 |

---

## 3. 必須制作パイプライン（5-Stage Workflow）

### Layer 1（Mode A / B 共通）

1. **Stage 1：PR解析・裏取り・意味的クラスタリング**
   - 👉 [references/pr-analysis-and-storyboard.md](./references/pr-analysis-and-storyboard.md) を読み込み、PR/ブランチ差分を取得してノイズを除外、周辺 1〜4ファイルを実読して裏取りする。
   - 変更を**最大3関心事クラスタ**かつ依存順へ配列し、PRタイプ5分類（`feature` / `bugfix` / `refactor` / `architecture` / `ui`）と高リスク・Tao I-10 箇所を特定する。
2. **Stage 2：4ブロック・フォーマット非依存ストーリーボード JSON 策定**
   - `semantic_core` / `visual_directive` / `adapter_silent_theater` / `adapter_narrated_video` の4ブロック構造でビートを設計する（UI変更PRは隔離 `git worktree`＋Playwright実画面録画を計画）。
   - 👉 [references/code-visual-patterns.md](./references/code-visual-patterns.md) を読み込み、PRタイプ別比率・1080p視認性・10大Gotchas回避を設計へ反映する。

### Layer 2（Mode A / Mode B 分岐）

- **Mode A（無音 HTML/SVG 再生シアター：デフォルト）を選択した場合**:
  3. **Stage 3A**：`adapter_silent_theater` のキャプション（最大2行・日本語 $\le 32$文字）と無音5フェーズ時間（ms）を確定する。
  4. **Stage 4A**：👉 [references/theater-engine-patterns.md](./references/theater-engine-patterns.md) のみを読み込み、ゼロ依存 2ペイン再生シアター（左：SVGフロー＋Before残像、右：抜粋コード $\le 12$行＋`file:line` バッジ、`data-key` 連動、再生・1ビート戻し/送り・速度・`prefers-reduced-motion`）を実装する。
  5. **Stage 5A**：第4節の **共通ゲート + Mode A ゲート** で自己監査して出力する。

- **Mode B（音声ナレーション付き MP4/WebM 動画）を選択した場合**:
  3. **Stage 3B**：👉 [references/narrated-video-pipeline.md](./references/narrated-video-pipeline.md) のみを読み込み、`adapter_narrated_video` へ話し言葉TTS原稿（記号・生パス除去、日本語 `270–320`文字/分・英語 `160–185 WPM`）を記述し、ビート単位で TTS 音声＋タイムスタンプを先生成して Audio-First 尺を確定する（300秒超なら Stage 2 へ差し戻し圧縮）。
  4. **Stage 4B**：Remotion（または仮想クロック HTML＋Playwright）で実測音声尺からフレーム数（`30 fps`）を算出し、発話語の `50–100 ms` 先行でハイライト・Magic Move を同期レンダリングして `.vtt` 字幕を同時出力する。
  5. **Stage 5B**：FFmpeg で `libx264 (yuv420p, -g 60, +faststart)` ＋ `AAC 96k (-14 LUFS)` へエンコード（`9.5 MB` 超過時は CRF引き上げ→720p 自動フォールバック）、代表フレームの視覚検査と `ffprobe` を通し、第4節の **共通ゲート + Mode B ゲート** を全通させて納品する。

---

## 4. 出力前 自己監査チェックリスト（Binary Audit Gate）

### 共通ゲート（Mode A / B 必須）
- [ ] **共通1（BLUF＆因果・尺）**: 冒頭 `10–15秒`（第1ビート）で変更目的・結論・影響範囲・不変条件を完結提示し、全体が目標尺（標準 `60–180秒`・上限 `300秒`）に収まっているか。
- [ ] **共通2（依存順＆同時提示）**: ファイル名順ではなく依存・意味クラスタ順（$\le 3$ 関心事）に並び、関連変更や Before/After が同一画面で比較可能（180°ルール・Before残像維持）か。
- [ ] **共通3（裏取り＆生diff禁止）**: 周辺 1〜4ファイル実読に基づく正確な `file:line` を示し、生 diff や 19行以上のコード詰め込み・`Why` を語らない逐語実況を排除したか。
- [ ] **共通4（リスク＆類似箇所）**: 高リスク変更・AI生成落とし穴・**類似箇所への一貫性（Tao I-10）**をフェーズ⑤で漏れなく点検したか。

### Mode A 追加ゲート（無音 HTML/SVG シアター）
- [ ] **A1（無音同期）**: 日本語 `4.0 CPS`/英語 `17 CPS` の Phase A 読解静止完了前にモーションが発火せず、キャプションは2行・上限文字数以内か。
- [ ] **A2（抜粋上限）**: 右ペインのコードが `12行以下`、非注目行ディミング済みで、`data-key` 連動と `file:line` バッジが揃っているか。
- [ ] **A3（MOT＆間）**: 同時独立移動が `4個以下`、`linear` イージング禁止、各ビート末に `>= 1000 ms`（重要ビート `>= 1800 ms`）の定着ホールドがあるか。
- [ ] **A4（決定論＆アクセシビリティ）**: シーク・1ビート戻し/送りで状態同期が破綻せず、`prefers-reduced-motion` 自動検知＋手動トグルで成立するか。

### Mode B 追加ゲート（音声付き MP4/WebM 動画）
- [ ] **B1（TTS原稿適正）**: 話し言葉中心で `Why`/トレードオフを語り、記号（`< > &`）・生パス・未展開識別子・句読点連打ポーズを含んでいないか。
- [ ] **B2（Redundancy排除）**: 音声と同一の長文テロップを画面に焼き込まず、2–3語アンカーラベル＋分離 `.vtt` 字幕（かつ冒頭5–10秒はミュート完結）になっているか。
- [ ] **B3（Audio-First同期）**: 全ビートのフレーム数が実測TTS尺＋ポーズから算出され、音声先行（`> 45 ms` 厳禁）がなく視覚変化が `0–100 ms` 先行しているか。
- [ ] **B4（可読性＆配信仕様）**: コード `28–32 px`・行間1.5倍・`<= 18行`・`<= 80文字/行`・コントラスト `>= 4.5:1`、代表フレーム視覚検査で重なりゼロ、`ffprobe` で `h264 / yuv420p / 30fps / +faststart / aac (-14 LUFS)` かつ **`<= 9.5 MB`** を満たすか。

---

## 5. リファレンス一覧（Progressive Disclosure）

- **[references/pr-analysis-and-storyboard.md](./references/pr-analysis-and-storyboard.md)**: 【Layer 1 共通】一次文献エビデンスマップ＆留保、PR/ブランチ解析、ノイズ除外・裏取り、クラスタリング手順、PRタイプ別比率表、4ブロック中間ストーリーボード JSON 仕様。
- **[references/code-visual-patterns.md](./references/code-visual-patterns.md)**: 【Layer 2 共通】6フェーズ別ビジュアル語彙・1080p画素可読性基準、Focus+Context・Magic Move・分割比較、PRタイプ別演出表、10大アンチパターン（Gotchas #1–#10）。
- **[references/theater-engine-patterns.md](./references/theater-engine-patterns.md)**: 【Mode A 専用】無音5フェーズ決定論エンジン、2ペイン／分割コード表示、Progressive Path＆残像、`generative_ui` テンプレート。
- **[references/narrated-video-pipeline.md](./references/narrated-video-pipeline.md)**: 【Mode B 専用】CTML原則反転、TTS脚本・話速・SSML規約、動画生成4スタック選定（Remotion / Playwright+FFmpeg 等）、ElevenLabs/VOICEVOX/WhisperX Audio-First同期、H.264/9.5MBエンコード自動化・視覚検査ガイド。
