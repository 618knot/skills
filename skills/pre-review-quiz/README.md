# pre-review-quiz

PRをコードレビューに出す前や、調査Issue・技術選定ドキュメントを共有する前に、作成者自身が「対象固有の要点」と「関連する技術知識」を1問ずつの対話形式で解き、理解を深めて Obsidian 向け Markdown ログを残す Agent Skill です。

---

## 必須設定の有無

**必須の事前設定はありません。** 何も設定しなくてもそのまま対話クイズを実行でき、Obsidian ログの保存先が未設定の場合は、クイズ終了時に保存先パスを入力するかスキップ（またはチャット出力）を選べます。

ただし、用途に応じて以下の2点を用意・設定しておくとスムーズに運用できます。

| 項目 | 必要度 | 対象・役割 |
| :--- | :--- | :--- |
| **GitHub CLI (`gh`) の認証** | GitHub PR / Issue を使う場合のみ必要 | `gh pr view` / `gh issue view` の取得に使用（`gh auth status` で確認）。ローカルの `git diff` や Markdown ファイルのみなら不要。 |
| **Obsidian ログ保存先の設定** | 推奨（任意） | 毎回保存先を指定せずに Vault へ出力したい場合に、設定ファイルまたは環境変数で指定。 |

---

## セットアップ（スキルの有効化）

リポジトリルートで [setup.sh](../../setup.sh) を実行すると、`~/.gemini/config/skills/pre-review-quiz` および `~/.claude/skills/pre-review-quiz` へシンボリックリンクが作成されます。

```bash
./setup.sh
```

---

## Obsidian ログ保存の設定方法

保存先とファイル名は以下の優先順位で解決されます（上位が優先）。

1. **実行時のユーザー指定**（例：「ログは `~/Vault/ReviewQuiz` に保存して」）
2. **環境変数**：`PRE_REVIEW_QUIZ_LOG_DIR`（任意で `PRE_REVIEW_QUIZ_FILENAME_TEMPLATE`）
3. **リポジトリ内設定**：`.pre-review-quiz.yaml` または `.agents/pre-review-quiz.yaml`
4. **ユーザーグローバル設定**：`~/.config/pre-review-quiz/config.yaml`
5. **未設定時**：クイズ終了時に保存先を尋ねる／スキップ／チャット上への Markdown 出力を選択

### 方法A：設定ファイルを使う（推奨）

同封の [config.example.yaml](./config.example.yaml) をユーザーグローバル設定へコピーして編集します。

```bash
mkdir -p ~/.config/pre-review-quiz
cp skills/pre-review-quiz/config.example.yaml ~/.config/pre-review-quiz/config.yaml
```

> [!NOTE]
> 個人のローカルパス（`~/Documents/ObsidianVault/...` 等）をリポジトリ直下の `.pre-review-quiz.yaml` に書く場合は、チームリポジトリへ誤コミットしないよう `.gitignore` に追加するか、上記 `~/.config/pre-review-quiz/config.yaml`（グローバル配置）の利用を推奨します。

#### 設定キー一覧

| キー | デフォルト値 | 説明 |
| :--- | :--- | :--- |
| `log_dir` | 未設定（コメントアウト） | Obsidian Vault 内のログ保存先ディレクトリ（絶対パスまたは `~` 展開可能なパス）。 |
| `filename_template` | `"{{date}}_{{type}}-{{id_or_slug}}.md"` | 出力ファイル名テンプレート。`{{date}}`, `{{type}}`, `{{id_or_slug}}`, `{{repo}}` を利用可能。既存ファイルがある場合は `-2`, `-3` を付与して上書き防止。 |
| `save_behavior` | `ask` | `ask`: 終了時に保存先確認 / `auto`: `log_dir` 設定済みなら確認せず保存 / `skip`: 保存をデフォルトでスキップ。 |
| `default_tags` | `[review-quiz]` | Frontmatter の `tags` に常に含めるベースタグ（`#` なし・小文字ケバブケース推奨）。 |

### 方法B：環境変数を使う

シェルの設定ファイル（`~/.zshrc` 等）に以下を追記します。

```bash
export PRE_REVIEW_QUIZ_LOG_DIR="$HOME/Documents/ObsidianVault/ReviewQuiz"
# 任意：ファイル名テンプレートを変えたい場合
export PRE_REVIEW_QUIZ_FILENAME_TEMPLATE="{{date}}_{{type}}-{{id_or_slug}}.md"
```

### 補足：ワークスペース外（Obsidian Vault）への書き込みについて

Obsidian Vault が作業中のリポジトリ外にある場合、エージェント実行環境のサンドボックス設定によっては、ファイル書き込み時にユーザー承認が求められたり直接書き込みが制限されたりすることがあります。直接書き込めない場合は、チャット上に完成版の Markdown 全文を出力してそのまま貼り付けられるように振る舞います。

---

## 使い方の例

### PRモード（コード変更）
- 「今のブランチのPRを出す前に理解度クイズを出して」
- 「PR #142 のセルフレビュークイズをお願い」
- 「まだPRを作ってないけど、`main` との差分で理解確認したい」

### 調査Issue / ドキュメントモード
- 「Issue #87 を共有する前に理解度チェックをして」
- 「`docs/rfc/cache-strategy.md` の技術選定ドキュメントでクイズを出して」

### 保存先を一時指定して実行する例
- 「このPRで理解確認クイズをして。ログは `~/Documents/ObsidianVault/Work/ReviewQuiz` に保存して」

---

## 個別チューニング・カスタマイズ一覧

出題観点・問題数配分・ヒントの出し方・Obsidian 出力形式はファイル単位で分離されているため、運用に合わせて個別に調整できます。

| 調整したい項目 | 編集対象ファイル | 主なチューニング内容 |
| :--- | :--- | :--- |
| **全体フロー・厳守ルール・発動条件** | [SKILL.md](./SKILL.md) | 起動トリガー（`description`）、共通ルール、4ステップの流れ |
| **PRモードの基準・観点** | [references/pr-mode.md](./references/pr-mode.md) | ノイズ除外対象、高リスク判定基準、AIコード落とし穴、PR 5カテゴリの作問例 |
| **Issue / Docモードの基準・観点** | [references/issue-doc-mode.md](./references/issue-doc-mode.md) | 裏取り対象、重要度判定基準、Issue/Doc 5カテゴリの作問例 |
| **問題数・配分・難易度・禁止ルール** | [references/question-design.md](./references/question-design.md) | 総問題数（2〜6問）、対象要点 vs 技術知識の比率、MC比率、禁止問題、内部難易度（`Lv.1`〜`Lv.3`）基準 |
| **対話進行・ヒント・深掘り** | [references/dialogue-and-hints.md](./references/dialogue-and-hints.md) | 浅い回答への1回深掘り条件、ヒント1/2の粒度、3回目解説の基準、異議申し立て対応 |
| **Obsidian ログ仕様・テンプレート** | [references/obsidian-log-format.md](./references/obsidian-log-format.md) | Frontmatter プロパティ、Wikilink/タグ規則、Callout 記法、Markdown テンプレート |
| **デフォルト設定ファイル雛形** | [config.example.yaml](./config.example.yaml) | `log_dir`, `filename_template`, `save_behavior`, `default_tags` の雛形 |
