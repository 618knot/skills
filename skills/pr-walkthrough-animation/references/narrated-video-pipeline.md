# 【Layer 2-B 専用】Audio-First 音声付き PR 解説動画パイプライン（MP4 / WebM ＋ WebVTT）

本ドキュメントは、Layer 1 の 4ブロック中間 JSON（`semantic_core` ＋ `visual_directive` ＋ `adapter_narrated_video`）を消費し、音声ナレーション付きの MP4 解説動画および `.vtt` 字幕を自律生成する **Mode B** の設計・実装・配信規約を定義する。

---

## 1. Mode A（無音Web）から Mode B（音声動画）への4大設計パラダイム反転

無音 Web シアター（Mode A）のルールを音声動画へそのまま流用してはならない。言語処理を**聴覚チャネル**へオフロード（Modality 原則：$d = 0.72$、出版バイアス補正後 $d = 0.20$）することで、以下の4点を反転させる。

1. **時分割排他 → 時間的近接（同時並列）**:
   - Mayer の Temporal Contiguity 原則（$d = 1.30\text{–}1.31$）に従い、音声で解説している**まさにその瞬間**に対応するノード点灯・コードハイライトを実行する。
   - **ITU-R BT.1359-1 同期閾値**：音声が映像より **`45 ms` 超先行**すると不快なズレとして知覚されるため厳禁。逆に映像が先行し音声が最大 `125 ms` 遅れるズレは非知覚であるため、**視覚変化を音声開始より `50–100 ms`（`30 fps` で `2フレーム`）先行**させて視線を誘導する。
2. **長文テロップ表示 → Redundancy 排除 ＋ 短語アンカー ＋ 分離 WebVTT**:
   - 音声と同一の長文を画面に焼き込むと、高速進行時に注意分割が生じる（Mayer 2024 Table 6: $d = 0.10$）。一方、Mayer & Johnson (2008) の逆冗長性境界条件により、**図・コード直近の `2–3語` キーワードラベル**（空間近接 $d = 0.79$）と**オンオフ可能な分離字幕**は有効である。
   - **二重防衛**：画面には長文テロップを焼き込まず `2–3語` アンカーラベルのみ配置し、全文字幕は `.vtt` サイドカーファイルとして分離出力する。さらに GitHub PR / Slack のミュート自動再生に備え、**冒頭 `5–10秒` の TL;DR カードと各チャプター見出しは音声オフでも概要が完結**するよう設計する。
3. **視覚と聴覚の厳密な役割分担**:
   - **視覚（画面）が担当する内容（What / Where / Structure）**：空間構造（アーキテクチャ/データフロー）、Shiki Magic Move トークン変形、ファイル座標バッジ（`file:line`）、リスク警告ラベル。
   - **聴覚（音声）が担当する内容（Why / Trade-off / Causality）**：変更の背景・動機、**採らなかった代替案とトレードオフ**（MacLeod et al., 2015）、因果の接続、エッジケースと類似箇所（Tao I-10）への注意点。画面に映る構文をそのまま読み上げてはならない。
4. **Video-First → Audio-First（音声尺駆動）**:
   - 「シーン1は10秒」と映像フレーム数を先に決め打ちする（Video-First）と、音声切れ・倍速圧縮・同期破綻が起きる。必ず **ビート単位の TTS 先生成 → 実測音声尺＋ポーズからの総フレーム数逆算（Audio-First）** で構築する。

---

## 2. TTS ナレーション脚本・話速・SSML 執筆ルール

Craig & Schroeder (2017, 2019) が実証した通り、現代的高品質 TTS は学習成果・認知効率・信頼性で録音人間音声と有意差がない（旧世代比 $d = 0.58, p = 0.01$）。ただし自然さは信頼感に直結し、会話調表現（Personalization $d = 1.00$）が理解を深めるため、以下の執筆規約を厳守する。

- **目標話速とビート内文字数目安**:
  - **日本語（NHK式基準 `300文字/分` ≒ `5.0文字/秒`）**：TL;DR 導入 **`310–340文字/分`**、通常図解 **`280–300文字/分`**、コード変形・リスク解説 **`260–290文字/分`**。
  - **英語（Guo et al., 2014 × Miao et al., 2020 の交点）**：**`160–185 WPM`**（コード・高リスク帯は `150–170 WPM`）。
- **TTS 原稿からの禁止事項（書き言葉・記号の排除）**:
  - **NEVER**: `< > & 「」` 等の SSML 破損記号、生ファイルパス（`src/auth/jwt_refresh_handler.ts`）、長い `camelCase` / `snake_case` 識別子、演算子記号（`!==`, `=>`）、句読点連打（`、、、`）や小文字「っ」による擬似ポーズ。
  - **MUST**: パスや識別子は「認証ハンドラのトークン更新処理」のように自然言語の意味ラベルへ言い換え、正確な綴りは画面上の `file:line` バッジ・抜粋コードへ委譲する。
- **SSML `<break>` ポーズ基準（または Audio-First 無音パディング）**:
  - 文間ポーズ：`300–400 ms`（`<break time="350ms"/>`）
  - 課題・リスク点灯直後：`400–500 ms`
  - コード変形（Magic Move）完了直後の定着：`500–700 ms`
  - チャプター（幕）遷移間：`800–1,000 ms`
  - 最終フレーム（まとめ）静止保持：`1,500–2,000 ms`

---

## 3. プログラマティック動画生成スタック比較＆選定ガイド

> [!NOTE]
> 各スタックの AI 動画生成スキルを同一条件で評価した独立の査読付きベンチマークは存在しない。以下は OSS 構造・公式仕様・実務評価に基づく選定基準である。

| 評価軸 | **Remotion**（React + TS + Headless Chrome + FFmpeg） | **仮想クロック HTML/SVG + Playwright + FFmpeg**（HyperFrames型） | Motion Canvas（TS + Canvas 2D） | Manim Community + manim-voiceover |
| :--- | :--- | :--- | :--- | :--- |
| **決定論性** | **最高**（`useCurrentFrame()` による純粋フレーム関数。CI 再現性が極めて高い） | **高**（仮想クロック制御でフレーム単位キャプチャすれば決定論的） | 中（ヘッドレス CI 化は追加構成が必要） | 高（Python シーン単位） |
| **コード変形（Magic Move）** | **最高**（**Shiki Magic Move / Code Hike** / Web フォントをネイティブ統合） | **最高**（ブラウザ標準 Shiki / SVG / HTML/CSS をそのまま描画） | 中（独自 Code コンポーネント。Web資産流用性低） | 低（LLM 生成時のテキスト重なり破綻に弱い） |
| **Audio-First 同期** | **最高**（`calculateMetadata` 内で実音声尺を取得しフレーム数を動的確定） | 良好（FFmpeg 音声結合＋マニフェストからフレーム計算） | 追加実装が必要 | 良好（音声尺伸縮を標準支援） |
| **ライセンス・資産共通化** | **組織・商用利用時は Remotion ライセンス確認必須**（再配布制限あり） | **OSS（Mode A の HTML/SVG 描画コードを 100% 共通利用可能）** | MIT ライセンス | OSS（Python） |

- **第1推奨（ライセンス条件を満たす環境）**: **Remotion ＋ Shiki Magic Move ＋ SVG ダイアグラム**
- **第2推奨（完全 OSS・ライセンスフリー、または Mode A 描画資産をそのまま使う環境）**: **仮想クロック駆動 HTML/SVG ＋ Playwright フレームキャプチャ ＋ FFmpeg**
- **UI変更 PR の必須サブパイプライン（主軸エンジン共通）**:
  - 隔離 `git worktree` で `Base` ブランチと `Head` ブランチ双方のアプリを起動し、同一の Playwright 操作スクリプトで **Before / After の実画面 MP4 クリップ** を自動録画して、主動画の並列比較レイアウトへ合成する。

---

## 4. Audio-First タイムライン実装＆タイムスタンプ取得仕様

### 4.1 エンジン別タイムスタンプ取得（ビート単位の先生成）
1. **タイムスタンプ対応 TTS API（例：ElevenLabs 等）**:
   - ElevenLabs の `POST /v1/text-to-speech/{voice_id}/with-timestamps` 等を呼び出し、`audio_base64` と同時に返る `alignment`（または `normalized_alignment`）の `characters`, `character_start_times_seconds`, `character_end_times_seconds` から強調語の開始時刻 `t_word` を抽出する。
2. **タイムスタンプ非対応 TTS（標準音声ファイル出力のみのエンジンや macOS `say` 等）**:
   - ワード／文字タイムスタンプを返さない TTS を使う場合は、後段に **WhisperX** による強制アライメント（Forced Alignment）を挟んで強調時刻を特定するか、またはビート総尺ベースでAudio-First同期するフォールバック経路を実行する。

### 4.2 Remotion `calculateMetadata` による決定論フレーム計算＆視覚先行同期
```typescript
import { parseMedia } from '@remotion/media-parser';

const FPS = 30;
const VISUAL_LEAD_SEC = 0.06; // ITU-R BT.1359-1 準拠: 60ms (約2フレーム) 視覚先行

export async function calculateVideoMetadata({ props }: { props: { beats: NarratedBeat[] } }) {
  let cursorFrame = 0;
  const scheduledBeats = [];

  for (const beat of props.beats) {
    const { slowDurationInSeconds } = await parseMedia({
      src: beat.audioFile,
      fields: { slowDurationInSeconds: true },
    });
    const postPauseSec = (beat.postPauseMs ?? 600) / 1000;
    const durationInFrames = Math.ceil((slowDurationInSeconds + postPauseSec) * FPS);

    // 強調語タイムスタンプ t_word から 60ms 先行したフレームへ視覚イベントをバインド
    const triggerFrames = (beat.emphasisTriggers ?? []).map((tr) => {
      const tVisual = Math.max(0, tr.wordStartSec - VISUAL_LEAD_SEC);
      return {
        dataKey: tr.dataKey,
        localFrame: Math.round(tVisual * FPS),
      };
    });

    scheduledBeats.push({
      ...beat,
      fromFrame: cursorFrame,
      durationInFrames,
      audioDurationSec: slowDurationInSeconds,
      triggerFrames,
    });
    cursorFrame += durationInFrames;
  }

  return {
    fps: FPS,
    width: 1920,
    height: 1080,
    durationInFrames: cursorFrame,
    props: { ...props, scheduledBeats },
  };
}
```
- **WebVTT（`.vtt`）同時出力**: 各ビートの累積開始時刻 `fromFrame / FPS` と文・ワードタイムスタンプから、追加推論なしで完全同期した `.vtt` 字幕ファイルを並行出力する。

---

## 5. エンコード・可読性・9.5 MB 容量ガードレール ＆ 視覚検査

### 5.1 配信規格パラメータ（GitHub PR / Slack 完全互換）
| パラメータ | 標準値（デフォルト） | 条件付きフォールバック | 技術的根拠 |
| :--- | :--- | :--- | :--- |
| **解像度 / FPS / GOP** | `1920 × 1080` / `30 fps` / `-g 60`（2秒GOP） | 容量逼迫時のみ `1280 × 720` / UI高速検証のみ `60 fps` | シーク・一時停止の即応性と CI 計算コスト削減 |
| **映像コーデック** | `H.264 (libx264)`, `-pix_fmt yuv420p`, `-crf 24 -preset slow`, `-movflags +faststart` | 9.5 MB超過時 `-crf 28` → なお超過時 `720p` | `yuv444p` や WebM は再生失敗する場合があり、`+faststart` で即再生開始 |
| **音声コーデック** | `AAC-LC 96 kbps`, `48 kHz`, `-14 LUFS`（`loudnorm=I=-14:TP=-1.5:LRA=11`） | モノラル時は `64–96 kbps` | 映像ビットレート帯域を最大化しつつ音量正規化 |
| **容量上限** | **`<= 9.5 MB`（ユニバーサル安全上限）** | 有料リポ明示時 `<= 100 MB`、Slack `<= 1 GB` | GitHub 無料リポ / `gh --attach` 上限が **10 MB** のため（Git 直接 push 厳禁） |

### 5.2 FFmpeg 自動エンコード・9.5 MB フォールバック＆検査スクリプト例
```bash
# 1. ラウドネス正規化 + H.264 (yuv420p, 2秒GOP, +faststart) エンコード
ffmpeg -y -i raw_render.mp4 \
  -c:v libx264 -pix_fmt yuv420p -crf 24 -preset slow -g 60 -movflags +faststart \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 96k -ar 48000 \
  pr_walkthrough.mp4

# 2. 容量ガードレール検査 (9,961,472 bytes = 9.5 MiB)
SIZE=$(wc -c < pr_walkthrough.mp4)
if [ "$SIZE" -gt 9961472 ]; then
  # 第1フォールバック: CRF 28 へ圧縮
  ffmpeg -y -i raw_render.mp4 -c:v libx264 -pix_fmt yuv420p -crf 28 -preset slow -g 60 -movflags +faststart -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 96k -ar 48000 pr_walkthrough.mp4
  SIZE=$(wc -c < pr_walkthrough.mp4)
fi
if [ "$SIZE" -gt 9961472 ]; then
  # 第2フォールバック: 720p へ縮小
  ffmpeg -y -i raw_render.mp4 -vf "scale='min(1280,iw)':-2" -c:v libx264 -pix_fmt yuv420p -crf 26 -preset slow -g 60 -movflags +faststart -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 96k -ar 48000 pr_walkthrough.mp4
fi

# 3. コーデック・色空間・GOP 機械検証 & 代表フレーム視覚検査用PNG抽出
ffprobe -v error -show_entries stream=codec_name,pix_fmt,r_frame_rate,width,height -of json pr_walkthrough.mp4
ffmpeg -y -i pr_walkthrough.mp4 -vf "select='eq(n,30)+eq(n,300)+eq(n,900)'" -vsync vfr inspect_%02d.png
```
- 抽出した代表フレーム静止画（TL;DR・抽象図・最大コード密度フレーム・高リスクカード）を視覚確認し、テキスト重なり・画面外クリップ・コントラスト不足（`< 4.5:1`）がゼロであることを検査してから納品する。

---

## 6. Mode B 出力前 12項目バイナリ配信監査チェックリスト

- **構成・認知ゲート（4項目）**
  - [ ] 冒頭 `10–15秒` で目的（Why）・結論・影響範囲・リスクが完結提示されているか（BLUF遵守）。
  - [ ] 総尺が PR タイプ別目標帯にあり、いかなる場合も **`300秒` 以下**（標準 `60–180秒`）か。
  - [ ] ファイル名アルファベット順ではなく依存・意味クラスタ順（$\le 3$ 関心事）で、順序規則が明示されているか。
  - [ ] ノイズ差分が除外され、高リスク箇所・AI生成落とし穴・**類似箇所の一貫性（Tao I-10）**がフェーズ⑤で漏れていないか。
- **音声・Audio-First 同期ゲート（4項目）**
  - [ ] ナレーション原稿に構文逐語朗読・生パス・SSML破損記号（`< > &` 等）・句読点連打がなく、Why とトレードオフを会話調で語っているか。
  - [ ] 画面キャンバス内に長文テロップを焼き込まず、2–3語アンカーラベル＋分離 `.vtt` 字幕になっているか。
  - [ ] 全ビートのフレーム数が実測 TTS 尺＋ポーズから算出され、音声切れ・重複・`45 ms` 超音声先行ズレがゼロか。
  - [ ] ミュート状態で冒頭 `5–10秒` と見出しだけ再生しても PR の概要と変化の要点が視覚的に成立するか。
- **視覚可読性・エンコード配信ゲート（4項目）**
  - [ ] 代表抽出キーフレームの視覚検査で、要素・文字の重なりや画面外クリップがゼロか。
  - [ ] コード表示フレームが **`18行` 以下（推奨 `10–15行`）・1行 `80文字` 以内・`28–32 px`・行間 `1.5倍`・コントラスト比 `4.5:1` 以上** か。
  - [ ] `ffprobe` で `h264`・`yuv420p`・`30fps`・`aac`（`-14 LUFS`）・`+faststart` が確認できるか。
  - [ ] 最終 MP4 サイズが **`<= 9.5 MB`**（有料リポ明示時のみ `<= 100 MB`）に収まっているか。
