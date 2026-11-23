# 【Layer 1】PR解析・意味的クラスタリング・出力非依存ストーリーボード仕様

本ドキュメントは、PR / ブランチ差分から「理解すべき本質」を抽出し、レンダリング形式（HTML/SVG シアター、将来の Remotion / MP4＋音声動画）に依存しない**ストーリーボード中間仕様**へ変換するまでの手順を定義する。

---

## 1. 入力ソースの取得（PR / ローカルブランチ両対応）

1. **PR が存在する場合（現在ブランチまたはユーザー指定の PR 番号 / URL）**:
   - `gh pr view <PR番号またはURL、省略時は現在ブランチ> --json number,title,url,body,baseRefName,headRefName,files,additions,deletions`
   - `gh pr diff <PR番号またはURL、省略時は現在ブランチ>`
2. **PR 作成前のブランチ／作業ツリーの場合（`gh pr view` が該当なし）**:
   - ベースブランチを特定（例：`origin/main` / `main`）し、以下を取得する：
     - `git status --short`
     - `git log <base>..HEAD --oneline`
     - `git diff --stat <base>...HEAD` および `git diff <base>...HEAD`
   - 未コミット変更のみ・ステージ済み変更を対象にする場合は `git diff` / `git diff --staged` を使う。

---

## 2. ノイズ差分の除外と周辺コンテキスト裏取り

### 2.1 視覚解説から除外するノイズ差分
以下に該当するファイルはアニメーションの主役から除外する（ただし新規依存追加の有無だけはリスク診断で検知する）：
- **Lockfile**: `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `Cargo.lock`, `go.sum`, `Gemfile.lock`, `poetry.lock`, `uv.lock`, `composer.lock`, `Podfile.lock` 等
- **バイナリ・メディア・フォント**: 画像、PDF、動画/音声、フォント、圧縮アーカイブ
- **ビルド生成物・自動生成コード**: `dist/`, `build/`, `.next/`, `out/`, `coverage/`, `*.min.*`, `*.bundle.*`, `*.pb.go`, `*.generated.*`, 巨大なスナップショット差分
- **フォーマット・空白のみの差分**: 制御フローやデータ構造に影響しないインデント・改行・クォート統一のみの変更

### 2.2 オンデマンドの周辺ファイル裏取り（diff 単体推測の禁止）
diff の断片だけから処理フローや副作用を推測してストーリーを作ってはいけない。変更内容に応じて **1〜4ファイル** を実際に読み込んで裏取りする：
- **呼び出し元・利用箇所**: 変更された関数・エンドポイント・コンポーネントの呼び出し元と型/I/F定義
- **関連テストファイル**: 追加・更新されたテスト、または既存テストの期待値変更箇所
- **スキーマ・設定・規約**: DBマイグレーション、環境変数/設定ファイル、ADR やリポジトリ規約（`AGENTS.md`, `docs/` 等）
- **同一セッションバイアスの排除**: 同じ会話内で AI 自身が実装した直後の場合でも、会話履歴の記憶に頼らず実際の diff と周辺ファイルを読み直して正確な行番号と挙動を確認する。

---

## 3. 規模トリアージ・PRタイプ分類・リスク診断

### 3.1 規模トリアージ
| 規模区分 | 判定目安 | 推奨ビート数と対応 |
| :--- | :--- | :--- |
| **極小・自明** | typo、コメント/ドキュメントのみ、20行未満で分岐・状態変更なし | 無理にフルアニメ化せず「テキスト要約で十分か、3ビートの簡易シアターにするか」を1行確認 |
| **標準** | 通常の機能追加、バグ修正、中規模リファクタ（実変更 20〜300行） | **5幕・6〜7ビート**（全体 60〜100秒目安） |
| **大規模・高リスク** | 複数モジュール横断、300行超、または高リスク要素を含む変更 | **5幕・8〜9ビート**（全体 100〜150秒目安）。枝葉のファイルはグルーピング圧縮して本質フローに絞る |

### 3.2 PRタイプ5分類（メイン演出の決定）
PR の主目的を以下の5分類（複合の場合は主・副を決定）へマッピングする：
1. **`bugfix`（バグ修正）**: 壊れた実行経路・異常状態の発生メカニズム → 根本原因箇所 → 修正後の正常経路
2. **`feature`（機能追加）**: 既存システムの拡張ポイント → 新規分岐・新規データフローの接続 → 既存挙動が不変であることの確認
3. **`refactor`（リファクタリング）**: 外部インターフェース／振る舞い不変の枠（Invariant）を固定 → 内部依存・重複の整理・簡素化
4. **`architecture`（構成・DB・非同期変更）**: コンポーネント間シーケンス・状態遷移・スキーマ変更の Before → After モーフィング
5. **`ui`（画面・状態UI変更）**: ユーザー操作イベント → 状態遷移 → レイアウト／表示状態の Before → After 比較

### 3.3 第4幕（Risk Audit）で必ず点検・ハイライトする項目
以下を1つでも検知した場合、**第4幕のビートとして必ず取り上げる**：
- **高リスク変更**:
  - DBスキーマ変更・マイグレーション・トランザクション・データ整合性
  - 認証・認可・権限境界・セッション・機密情報・課金/決済
  - 非同期処理・並行制御・ロック・キュー・キャッシュ無効化・リトライ
  - 外部API連携・タイムアウト・フォールバック・Webhook
  - 新規依存パッケージの追加
- **AI生成コード特有の落とし穴（自分の見落とし対策）**:
  1. **既存テストの期待値書き換え**: バグ修正ではなく新実装にテストを合わせて仕様変更を隠していないか
  2. **防御・検証の静かな弱体化**: 空の `catch`、雑なデフォルト値フォールバック、認可・バリデーション条件の緩和
  3. **既存ヘルパーとの重複実装**: リポジトリ既存ユーティリティと微妙に挙動が違う独自実装の追加
  4. **境界値・空値・部分失敗の未処理**: `null` / 空配列 `[]` / タイムアウト時に状態が中途半端に残らないか

---

## 4. 変更の意味的クラスタリング手順（Semantic Reading Order）

コードレビュー認知研究（Baum et al., 2019; Barnett et al., 2015）に基づき、**ファイル名アルファベット順を破棄**し、以下の順で変更ハンクをグループ化・配列する：

1. **変更ハンクの責務ラベル付け**: 各差分を `entry-point`（API/UI入口）、`domain-core`（中心ロジック）、`data-io`（DB/外部API/状態保存）、`guard-error`（エラー・認可・境界処理）、`test-spec`（テスト）に分類する。
2. **トップダウン実行順への並べ替え**:
   - **第1幕（TL;DR）**: PR全体の目的＋影響モジュール地図＋不変条件
   - **第2幕（Before）**: 変更前の入口〜問題箇所（または既存拡張点）
   - **第3幕（Core Flow）**: `entry-point` → `domain-core` → `data-io` の実行順に 1責務＝1ビートで連結（複数ファイルに跨る1つのデータフローは1ビートに統合する）
   - **第4幕（Risk & Edge）**: `guard-error` と高リスク／異常系シナリオのトレース
   - **第5幕（Test & Summary）**: `test-spec` のカバー範囲＋変更ファイル一覧マップ
3. **ビート数圧縮ルール**: 変更ファイルが10個以上ある大規模PRでも、細部ファイルごとにビートを増やさず（最大9ビート厳守）、同質の定型変更（例：型定義の追従、複数呼び出し元の引数追加）は `Common Fate` として1つの集約ノードに束ねる。

---

## 5. 出力非依存ストーリーボード中間仕様（Layer 1 → Layer 2 契約）

Stage 2 の成果物として、以下の構造でストーリーボードを内部確定する。**このデータ構造は Layer 2（HTML/SVG シアター）だけでなく、将来 Remotion / MP4＋音声ナレーション版レンダラを追加する際の共通入力スキーマとして機能する。**

```json
{
  "meta": {
    "target": "PR #142 (or branch feat/cache-invalidation)",
    "prType": "bugfix | feature | refactor | architecture | ui",
    "tldr": "1文での結論要約（目的と結果）",
    "invariants": ["変えてはいけない既存仕様・不変条件"],
    "riskSummary": ["第4幕で強調する高リスク／見落とし観点"]
  },
  "cast": [
    { "id": "api-handler", "label": "API入口", "role": "entry", "colorToken": "sky" },
    { "id": "cache-layer", "label": "キャッシュ層", "role": "core", "colorToken": "emerald" },
    { "id": "db-store", "label": "DB永続化", "role": "io", "colorToken": "amber" }
  ],
  "beats": [
    {
      "id": "b1-tldr",
      "act": "TLDR | Before | Core | Risk | Summary",
      "title": "ビート見出し（短語）",
      "caption": "2行以内・日本語32全角文字以内の極短キャプション",
      "narrationScript": "（将来B案・音声TTS用の自然な読み上げ原稿。A案では省略可）",
      "focusFiles": ["src/cache/service.ts:L42-L53"],
      "diagram": {
        "activeNodes": ["cache-layer", "db-store"],
        "dimNodes": ["api-handler"],
        "activeEdges": [{ "from": "cache-layer", "to": "db-store", "style": "progressive-path", "dataKey": "invalidate" }],
        "ghostBefore": true
      },
      "code": {
        "file": "src/cache/service.ts",
        "lineRange": "L42-L53",
        "mode": "before | diff-focus | after",
        "lines": [
          { "num": 42, "text": "await db.update(user);", "state": "context" },
          { "num": 43, "text": "- // 旧: キャッシュ削除漏れ", "state": "removed", "dataKey": "invalidate" },
          { "num": 44, "text": "+ await cache.del(key);", "state": "added", "dataKey": "invalidate" }
        ]
      },
      "riskTag": null,
      "timing": {
        "cueMs": 300,
        "motionMs": 1000,
        "holdMs": 1400
      }
    }
  ]
}
```
