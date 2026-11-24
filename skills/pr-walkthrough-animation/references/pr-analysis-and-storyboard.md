# 【Layer 1 共通】一次文献・PR解析・意味的クラスタリング・4ブロックストーリーボード仕様

本ドキュメントは、Mode A（無音 HTML/SVG シアター）と Mode B（音声ナレーション付き MP4/WebM 動画）の共通土台となる一次文献知見、PR/ブランチ差分解析手順、意味的クラスタリング基準、および媒体非依存の4ブロック中間 JSON 仕様を定義する。

---

## 1. 一次文献エビデンスマップ（および学術的留保）

| 領域 | 著者・発表年 | 原典タイトル | 核心概念・定量データ | スキル設計への直接的示唆 |
| :--- | :--- | :--- | :--- | :--- |
| **コード変更理解** | **Bacchelli & Bird (2013)** | *Expectations, Outcomes, and Challenges of Modern Code Review* (ICSE) | Microsoft開発者873名・マネージャ165名調査。最大の動機は欠陥発見だが実成果は知識移転（39%が主動機）が中心。最大の障壁は「変更理解」と「設計根拠（Design Rationale）」。 | 解説の主目的を「構文の朗読」ではなく「設計根拠（Why）とトレードオフの伝達」に置く。 |
| **開発者ニーズ** | **Tao, Dang, Xie, Zhang, & Kim (2012)** | *How Do Software Engineers Understand Code Changes?* (FSE) | エンジニア180名調査。4段階評価で最重要（`> 2`）は変更理由（`I-1`）、完全性・正当性・設計影響（`I-2〜4`）、破壊リスク（`I-9`）。最難関は**類似箇所への一貫性（`I-10`）**。 | 冒頭で `I-1`（理由）と `I-9`（リスク）を即答し、フェーズ⑤で類似箇所（`I-10`）と副作用の点検ビートを必ず設ける。 |
| **複合変更の分解** | **Barnett, Bird, Brunet, & Lahiri (2015)** / **Dias et al. (2015)** | *ClusterChanges* (ICSE) / *Untangling Fine-Grained Code Changes* (SANER) | Microsoft 1,000件中、単一パーティションは `45%` のみで約 `42%` が複合変更（誤結合0）。バグ修正コミットの `15–22%` が混在（Tangled）、`90%` 以上は **3関心事以下**。 | PRを平坦な差分リストとみなさず、リファクタやノイズを分離して本筋の**最大3関心事クラスタ**へ分解する。 |
| **最適閲覧順序** | **Baum, Schneider, & Bacchelli (2017, 2019)** | ICSME '17 / *Associating Working Memory Capacity and Code Change Ordering...* (EMSE '19) | 2017（292セッション・201名調査）：6原則（P1/P3関連グルーピング最優先、P4階層チャンキング、**P5関連変更の同一画面同時表示**、P6順序規則明示）。2019（50名実験）：WM容量は分散欠陥検出と相関する一方、**順序単独の効率差は統計的有意差なし**。 | アルファベット順を廃し依存順＋P6明示を行うが、順序単独を過信せず **P5（Before/Afterや関連2箇所の同一画面同時提示）** と小粒チャプターでWM負荷を直接下げる。 |
| **構成順序戦略** | **Wise et al. (2009)** / **Emde, Klimmt, & Schluetz (2016)** | *When Words Collide Online* / 逆ピラミッド対ナラティブ比較 (2016, 2017) | 逆ピラミッド（BLUF）は要旨即時把握に優れるが低事前知識者には認知負荷が高く詳細記憶・納得感が低下。因果ナラティブは詳細認識・没入を高める。 | 冒頭 `10–15秒` のみ BLUF とし、本編は「課題→設計→実装→検証」の因果ナラティブで構成するハイブリッド型を採る。 |
| **開発者動画研究** | **MacLeod, Storey, & Bergen (2015, 2017)** / **Ponzanelli et al. (2016)** | *Code, Camera, Action* (ICPC '15 / ESE '17) / *CodeTube* (ICSE '16) | 動的編集でコード変化を追跡でき、音声で「採らなかった別案」を伝えられる。障壁は編集コスト。CodeTube：開発者40名の `76.5%` が月1回以上動画利用。無構造スクロールは TL;DW を招く。 | 生スクロールを禁じ、自己完結チャプター＋Magic Move変形＋採用しなかった代替案の説明を自動生成する。 |
| **ガイド付き散策** | *CodeTour* / *Storyteller* / **Lacy (2026)** | *Simulating Expert Mentoring with Code Tours* (arXiv:2603.25391) | AIの局所スニペット翻訳はアーキテクチャ俯瞰を代替できない。ファイル座標アンカーと音声ガイドの併用が有効。 | 常に「全体図上の現在地」と `ファイルパス:行番号` バッジをコード抜粋と並置する。 |
| **動画尺と話速** | **Guo, Kim, & Rubin (2014)** / **Miao et al. (2020)** | *How Video Production Affects Student Engagement* (ACM L@S '14) 他 | edX 690万視聴セッション分析：視聴維持中央値は最大 `6分` 頭打ち。**`0–3分` が最高維持（75%が3/4超視聴、事後着手56%）**、12分超は31%。英語高維持帯 `185–254 WPM`、専門理解帯 `150–200 WPM`。 | 標準尺は **`60–180秒`（厳格上限 `300秒`）**。重要変形完了直後に選択的一時停止（Selective Pausing）できる静止フレームを置く。 |

---

## 2. 入力ソースの取得（PR / ローカルブランチ両対応）

1. **PR が存在する場合（現在ブランチまたはユーザー指定の PR 番号 / URL）**:
   - `gh pr view <PR番号またはURL、省略時は現在ブランチ> --json number,title,url,body,baseRefName,headRefName,files,additions,deletions`
   - `gh pr diff <PR番号またはURL、省略時は現在ブランチ>`
2. **PR 作成前のブランチ／作業ツリーの場合（`gh pr view` が該当なし）**:
   - ベースブランチ（例：`origin/main` / `main`）を特定し、以下を取得する：
     - `git status --short`
     - `git log <base>..HEAD --oneline`
     - `git diff --stat <base>...HEAD` および `git diff <base>...HEAD`
   - 未コミット変更のみ・ステージ済み変更を対象にする場合は `git diff` / `git diff --staged` を使う。

---

## 3. ノイズ除外・周辺裏取り・規模＆リスク診断

### 3.1 除外するノイズ差分（ただし新規依存追加の検知のみ行う）
- **Lockfile**: `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `Cargo.lock`, `go.sum`, `Gemfile.lock`, `poetry.lock`, `uv.lock`, `composer.lock`, `Podfile.lock` 等
- **バイナリ・メディア・フォント**: 画像、PDF、動画/音声、フォント、圧縮アーカイブ
- **ビルド生成物・自動生成コード**: `dist/`, `build/`, `.next/`, `out/`, `coverage/`, `*.min.*`, `*.bundle.*`, `*.pb.go`, `*.generated.*`, 巨大なスナップショット差分
- **フォーマット・空白のみの差分**: 制御フローやデータ構造に影響しないインデント・改行・クォート統一のみ

### 3.2 オンデマンドの周辺ファイル裏取り（diff 単体推測の禁止）
diff の断片だけから処理フローや副作用を推測しない。変更に応じて **1〜4ファイル** を必ず実読して裏取りする：
- **呼び出し元・型定義**: 変更された関数・エンドポイント・コンポーネントの呼び出し元と型/I/F定義
- **関連テスト**: 追加・更新されたテスト、または既存テストの期待値変更箇所
- **スキーマ・設定・規約**: DBマイグレーション、環境変数/設定、ADR やリポジトリ規約（`AGENTS.md`, `docs/`）
- **類似箇所の横断検索（Tao I-10 対策）**: 同種処理や姉妹関数が他ファイルに存在しないかを grep/検索し、修正漏れ・一貫性リスクがないか確認する
- **同一セッションバイアスの排除**: AI 自身が実装した直後であっても会話記憶に頼らず実コードと行番号を再確認する

### 3.3 規模トリアージと第5ビート（Risk & I-10）必須点検項目
| 規模区分 | 判定目安 | 推奨構成と目標尺 |
| :--- | :--- | :--- |
| **極小・自明** | typo、コメント/ドキュメントのみ、20行未満で分岐・状態変更なし | 無理にフル制作せず「テキスト要約でよいか・3ビート簡易版にするか」を1行確認 |
| **標準** | 機能追加、バグ修正、中規模リファクタ（実変更 20〜300行） | **6フェーズ・6〜7ビート**（`60–120秒`、最大 `180秒`） |
| **大規模・高リスク** | 複数モジュール横断、300行超、または高リスク要素を含む変更 | **6フェーズ・8〜9ビート**（`120–240秒`、**厳格上限 `300秒`**）。枝葉の定型変更は代表例1–2件に圧縮 |

- **高リスク検知項目（1つでも該当すればフェーズ⑤で必ず解説）**:
  - DBスキーマ変更・マイグレーション・テーブルロック・トランザクション・データ整合性
  - 認証・認可・権限境界・セッション・機密情報・課金/決済
  - 非同期処理・並行制御・ロック・キュー・キャッシュ無効化・リトライ
  - 外部API連携・タイムアウト・フォールバック・Webhook・新規依存パッケージ追加
- **AI生成コード特有の落とし穴＆一貫性チェック（自分の見落とし防止）**:
  1. **既存テストの期待値書き換え**: 新実装に合わせてアサーションを緩めていないか
  2. **防御の静かな弱体化**: 空の `catch`、雑なデフォルト値、認可・バリデーション条件の緩和
  3. **既存ヘルパーとの重複実装**: リポジトリ既存ユーティリティとの挙動ズレ
  4. **類似箇所の一貫性（Tao I-10）**: 今回直したバグ・仕様変更が、同パターンの別関数・別エンドポイントに残っていないか

---

## 4. 意味的クラスタリング ＆ PRタイプ5分類テンプレート

### 4.1 意味的クラスタリング手順（Baum 6原則 ＋ Barnett/Dias 準拠）
1. **混在関心事の分離**: 本筋の機能/バグ修正と、ついでに入ったリファクタ・フォーマット変更を分離し、**最大3関心事クラスタ**にまとめる（Barnett et al., 2015; Dias et al., 2015）。
2. **依存関係順への配列（アルファベット順厳禁）**:
   - 各差分を `entry-point`（入口）→ `domain-core`（中心ロジック）→ `data-io`（DB/外部API/キャッシュ）→ `guard-error`（境界/認可/リスク）→ `test-spec`（テスト）へ分類し、実行順・データフロー順に並べる。
3. **順序規則の明示と同時提示（Baum P5 & P6）**:
   - 冒頭（TL;DR）で「エントリポイントからDB永続化へのデータフロー順に追います」のように**並び順の規則を明示**し（P6）、密接に関連する2箇所（呼び出し元と呼び出し先、Before と After）は**分割画面等で同一フレーム内に同時表示**する（P5）。

### 4.2 PRタイプ5分類と抽象図：コード：実画面の標準比率
| PRタイプ | 目標動画尺 | 推奨構成比率（6フェーズ配分） | 主力ビジュアル語彙 | 抽象図 : コード : 実画面 | 最優先で語る論点（Why / Rationale） |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`feature`（機能追加）** | **120–180秒** | ①TL;DR(10%) → ②③設計フロー(30%) → ④核コード2–3クラスタ(35%) → ⑤異常系/認可(15%) → ⑥テスト(10%) | データフロー/シーケンス図 ＋ Magic Move（入口→コアの依存順） | **40% : 50% : 10%** | 新機能の全体像、責務分割の理由、既存機能（不変条件）への非干渉・境界条件 |
| **`bugfix`（バグ修正）** | **60–120秒** | ①TL;DR(15%) → ②③再現経路＆根本原因(25%) → ④最小修正Magic Move(30%) → ⑤副作用＆類似箇所(15%) → ⑥回帰テスト(15%) | 故障トレース図（赤強調）＋ 1画面Before/After変形 ＋ 回帰テスト赤→緑 | **35% : 55% : 10%** | 根本原因（Root Cause）、対症療法でない理由、類似箇所（Tao I-10）の有無 |
| **`refactor`（構造整理）** | **90–150秒** | ①TL;DR(10%) → ②Before負債(20%) → ③After＆依存逆転図(30%) → ④代表変換Magic Move(25%) → ⑤⑥不変性根拠(15%) | モジュール依存グラフの変形 ＋ 代表1–2例のみMagic Move（機械的置換は省略） | **60% : 40% : 0%** | 外部仕様不変の保証、複雑度・結合度の低下、代表例による横展開ルール |
| **`architecture`（構成/DB）** | **150–240秒**（上限300秒） | ①TL;DR(10%) → ②現行ボトルネック(15%) → ③新構成/ER移行図(35%) → ④マイグレーション/ロック/互換(25%) → ⑤⑥ロールバック＆検証(15%) | システムトポロジ図 ＋ スキーマ差分 ＋ ゼロダウンタイム移行図 ＋ 危険クエリ抜粋 | **65% : 30% : 5%** | 移行の安全性（ロック・後方互換性）、ロールバック可能性、運用トレードオフ |
| **`ui`（画面・状態変更）** | **60–120秒** | ①TL;DR(10%) → ②課題のBefore実画面(15%) → ③④Before/After並列実画面比較(40%) → ④状態管理コアコード(20%) → ⑤エッジ状態(15%) | **隔離 `git worktree` ＋ Playwright録画によるBefore/After左右比較** ＋ 状態遷移図 | **15% : 25% : 60%** | UX改善点、ローディング・空データ・エラー・狭画面での崩れ防止策 |

---

## 5. 2層共通・フォーマット非依存4ブロックストーリーボード JSON スキーマ

Stage 2 では表現媒体固有のタイムライン値（秒・フレーム数）を混ぜず、以下の**4ブロック分離スキーマ**を単一ハブ（Single Source of Truth）として確定する。

```json
{
  "pr_metadata": {
    "target": "PR #142 (or branch feat/cache-invalidation)",
    "pr_type": "bugfix",
    "tldr": "ユーザー更新時のキャッシュ削除漏れを修正し、古い権限参照を防ぐ",
    "invariants": ["DB更新失敗時はキャッシュを削除しない", "既存のレスポンス型を変更しない"],
    "ordering_rule": "エントリポイント → キャッシュ更新層 → 類似箇所点検 → 回帰テストの依存順",
    "excluded_noise": { "lockfiles": 1, "generated": 0, "formatting_only": 2 },
    "risk_summary": ["トランザクション外でのキャッシュ削除失敗時の扱い", "ロール変更エンドポイント（類似箇所I-10）の確認"]
  },
  "clusters": [
    {
      "cluster_id": "c1-cache-invalidation",
      "title": "更新直後のキャッシュ無効化と類似経路",
      "order_index": 1,
      "beats": [
        {
          "id": "b4-invalidate-fix",
          "semantic_core": {
            "phase": "code_focus",
            "tao_needs_addressed": ["I-1", "I-3", "I-9"],
            "file_anchor": { "file": "src/cache/service.ts", "symbol": "updateUserProfile", "line_range": "L42-L50" },
            "rationale_why": "TTL短縮ではなく即時削除を選んだ理由：権限変更の遅延反映をゼロにするため。DBコミット後に実行しロールバック不整合を防ぐ。"
          },
          "visual_directive": {
            "visual_mode": "code_magic_move",
            "diagram_diff": {
              "active_nodes": ["service-core", "redis-cache"],
              "dim_nodes": ["api-gateway"],
              "active_edges": [{ "from": "service-core", "to": "redis-cache", "style": "progressive-path", "data_key": "invalidate" }],
              "ghost_before": true
            },
            "anchor_keywords": [
              { "text": "コミット後削除", "data_key": "invalidate", "tone": "emerald" },
              { "text": "旧: 削除漏れ", "data_key": "invalidate", "tone": "rose" }
            ],
            "code_states": [
              {
                "file": "src/cache/service.ts",
                "line_range": "L42-L50",
                "lines": [
                  { "num": 42, "text": "await db.transaction(async (tx) => {", "state": "context" },
                  { "num": 43, "text": "  await tx.update(users).set(input);", "state": "context" },
                  { "num": 44, "text": "});", "state": "context" },
                  { "num": 45, "text": "// 旧: キャッシュがTTL切れまで残存", "state": "removed", "data_key": "invalidate" },
                  { "num": 46, "text": "await cache.del(`user:${userId}`);", "state": "added", "data_key": "invalidate" }
                ]
              }
            ]
          },
          "adapter_silent_theater": {
            "caption": "DBコミット直後にキャッシュを削除し\n古い権限データの残存を防ぐ",
            "cue_ms": 300,
            "motion_ms": 1000,
            "hold_ms": 1500
          },
          "adapter_narrated_video": {
            "narration_ssml": "ここで、あえてティーティーエルを短くする案ではなく、即時削除を選びました。<break time=\"400ms\"/>データベースのトランザクションが確定した直後にキャッシュを消すことで、ロールバック時の不整合を防ぎつつ古い権限が残らないようにしています。",
            "emphasis_triggers": [
              { "word": "即時削除", "data_key": "invalidate", "offset_ms": -60 },
              { "word": "キャッシュを消す", "data_key": "invalidate", "offset_ms": -60 }
            ],
            "post_pause_ms": 700,
            "audio_file": null,
            "measured_duration_sec": null,
            "word_timestamps": [],
            "computed_frames": null
          }
        }
      ]
    }
  ]
}
```
