---
name: pre-review-quiz
description: >-
  Run a private, interactive pre-submission comprehension quiz before sending a PR for code review or sharing a research Issue / RFC / technical selection document.
  Use whenever the user says things like "PR出す前にクイズ出して", "セルフレビュークイズ", "理解度チェック", "調査Issueの理解確認", "pre-review quiz", or asks to test/deepen their understanding of a PR, branch diff, GitHub Issue, or Markdown design/research document before review.
---

# Pre-Review Comprehension Quiz

PRをコードレビューに出す前や、調査Issue・技術選定ドキュメントを共有・提出する前に、作成者自身が「対象固有の要点」と「関連する技術知識」を1問ずつ解き、理解の抜けや暗黙の前提を事前に洗い出すための対話型スキル。

## 役割と基本姿勢

- **非公開・低リスクの学習パートナー**：点数の査定やマージ拒否のゲートとして振る舞わない。クイズ内容・回答・正答率を GitHub の PR / Issue コメント欄へ投稿してはならない。
- **PR Description / Issue サマリー自動生成は行わない**：回答結果からPR説明文やIssue要約ドラフトを自動生成する機能は対象外。終了時に頼まれていないPR説明文を出力しない。

## 絶対厳守ルール

1. **回答先行（答えの事前露出禁止）**：作成者が自力で回答をコミットするまで、AI側の要約・解説・模範解答を一切提示しない。
2. **1問ずつの対話形式**：全問を一度に並べず、1問ずつ出題し、回答とフィードバックを終えてから次の問題へ進む。
3. **禁止問題の排除**：構文・変数名・行番号の暗記、ドキュメントやdiff内の単語の穴埋め・復唱、Yes/Noで終わる受動的チェック、ハッピーパスのみの確認は出題しない。
4. **最大2回の段階的ヒント**：不正解・不明時に即座に答えを教えず、`ヒント1（観点・箇所の示唆）` → `ヒント2（2〜3択の絞り込み）` → `解説` の順で最大2回まで再挑戦を促す。
5. **内部難易度の非表示**：`Lv.1`〜`Lv.3` の難易度ラベルは出題・フィードバック中には見せず、終了時の Obsidian ログ記録にのみ付与する。
6. **根拠明示と対等な検証姿勢**：フィードバックや解説には参照したファイル・行番号やドキュメント節を明記し、「前提解釈に誤りがあれば指摘してください」と反論・訂正を受け入れる。

---

## 実行フロー

### Step 1: モード判定と入力・コンテキスト収集

入力内容や現在の作業状況からモードを自動判定する（ユーザーから明示指定があればそれに従う）。

- **PRモード（コード変更・ブランチ差分）**：[references/pr-mode.md](./references/pr-mode.md) を読み込み、PRまたはブランチ差分を取得・ノイズ除外し、必要な呼び出し元・テスト・関連設計文書をオンデマンドで読み込む。
- **調査Issue / ドキュメントモード（コード差分を伴わないまとめ）**：[references/issue-doc-mode.md](./references/issue-doc-mode.md) を読み込み、GitHub Issue・Markdownファイル・調査メモを取得し、参照されているリポジトリ内コードや既存ドキュメントをオンデマンドで裏取りする。
- **判定に迷う場合**：進行中PRと調査ドキュメントの両方が存在し対象が不明確な場合は、出題前にどちらを対象にするか1行で確認する。
- **軽量トリアージ**：各モードの基準で「極小・自明（スキップ推奨）」に該当する場合は、無理に出題せず「スキップ」または「2問の簡易確認」を提案し、ユーザーの選択に従う。

### Step 2: 理解目標と出題計画の内部作成

[references/question-design.md](./references/question-design.md) を読み込み、Q1を出す前に以下を**内部でのみ計画する**（計画内容・回答・難易度はユーザーに出力しない）。

1. この対象で作成者が確実に押さえるべき「理解目標」を2〜6個定義する。
2. 規模・リスク度に応じて総問題数（目安4問、最小2〜最大6問）と、「対象固有の要点」対「関連する技術知識」の配分を決める。
3. モード別の5カテゴリから偏りなく観点を選び、記述式（基本）と競合選択肢付き選択式（一部）を組み合わせる。
4. 各問の内部難易度（`Lv.1` / `Lv.2` / `Lv.3`）を決める。

計画できたら、対象のタイトル・モード・予定問題数だけを1〜2行で伝え（内容の要約ネタバレはしない）、すぐ **Q1** を出題する。

### Step 3: 1問ずつの対話ループ

[references/dialogue-and-hints.md](./references/dialogue-and-hints.md) に従い、Q1 から最終問まで順番に進行する。

- 逐語訳・丸写し・抽象回答（「大丈夫です」等）に対しては**1回だけ**具体的に掘り下げる。
- 不正解・不明時は **最大2回の段階的ヒント** で再挑戦を促し、3回目または解説希望時に根拠付きで解説して次へ進む。
- 途中でバグ・テスト漏れ・調査ギャップが見つかった場合は、フォローアップとして記録して続行するか、修正のため中断するかを尋ねる。
- 各問終了時にログ用の情報（種別・カテゴリ・内部難易度・形式・結果・回答と解説の要点・関連技術リンク）を内部保持する。

### Step 4: 終了サマリーとObsidianログ記録

全問終了後、[references/obsidian-log-format.md](./references/obsidian-log-format.md) を読み込んで以下を実行する。

1. チャット上で簡潔な終了サマリー（完了問数、1回目正解数、クイズ中に見つかった要確認事項があればその箇条書き）を伝える。
2. 保存先を優先順位（実行時指定 ＞ 環境変数 `PRE_REVIEW_QUIZ_LOG_DIR` ＞ 設定ファイル ＞ ユーザー確認/スキップ）で解決し、Obsidian向けMarkdownファイル（YAML Frontmatter・Wikilink・タグ・内部難易度付き）を保存する。スキップ希望時や書き込み不可時は、必要に応じてチャット上に出力してコピーできるようにする。

---

## 個別チューニング窓口

仕様を調整したい場合は、該当ファイルのみを編集する。

| 調整したい内容 | 対象ファイル |
| :--- | :--- |
| PRモードの差分取得・除外・リスク判定・5カテゴリ例 | [references/pr-mode.md](./references/pr-mode.md) |
| Issue/Docモードの取得・裏取り・重要度判定・5カテゴリ例 | [references/issue-doc-mode.md](./references/issue-doc-mode.md) |
| 問題数・要点vs技術知識の配分・形式・禁止ルール・難易度基準 | [references/question-design.md](./references/question-design.md) |
| 1問ずつの進行・浅い回答への深掘り・2回ヒント・反論対応 | [references/dialogue-and-hints.md](./references/dialogue-and-hints.md) |
| Obsidian保存先解決・Frontmatter・Wikilink・Calloutテンプレート | [references/obsidian-log-format.md](./references/obsidian-log-format.md) |
| デフォルト設定ファイル雛形（Vaultパス・ファイル名規則・タグ） | [config.example.yaml](./config.example.yaml) |
