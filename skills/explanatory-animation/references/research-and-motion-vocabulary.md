# 一次文献サマリー＆解説意図別「モーション語彙・デザイン空間」リファレンス

本ドキュメントは、解説アニメーション（Explanatory Animation）を自律設計するための5領域の一次文献知見、物語アーク仕様、10種類の解説意図別モーション語彙マッピング、および判断トレードオフ基準を定義する。

---

## 1. 一次文献マスタ一覧表（5領域）

| 領域 | 著者・発表年 | 原典タイトル | 核心概念・定量データ | AI設計スキルへの直接的示唆 |
| :--- | :--- | :--- | :--- | :--- |
| **1. 教育アニメーションと認知モデル** | **Höffler & Leutner (2007)** | *Instructional animation versus static pictures: A meta-analysis* (*Learning and Instruction*) | 26研究・76比較。全体効果量 $d = 0.37$（95% CI `0.25–0.49`）。表象的（Representational）アニメーション $d = 0.40$（CI `0.26–0.53`）、手続き・運動知識 $d = 1.06$（CI `0.72–1.40`）。 | 装飾目的の動きを禁止し、構造変化や手続き的遷移そのものを表象するアニメーションのみを採用する。 |
| **1. 教育アニメーションと認知モデル** | **Berney & Bétrancourt (2016)** | *Does animation enhance learning? A meta-analysis* (*Computers & Education*) | 61実験・140比較・7,000名超。全体 $g = 0.226$（CI `0.12–0.33`, $p < .001$）。事実知識 $g = 0.336$、概念 $g = 0.162$、手続き $g = 0.387$（知識次元間差は非有意 $p = 0.28$）、応用 $g = 0.333$。システム制御ペース $g = 0.309$（$p < .001$）、音声解説併用 $g = 0.336$、付随テキストなし $g = 0.883$。 | 画面テキストと動きの同時提示は学習効果を減衰させる。無音Web UIではテキスト読解フェーズとモーションフェーズを時間分離する。 |
| **1. 教育アニメーションと認知モデル** | **Ploetzner et al. (2020) / Ploetzner (2021)** | *When learning from animations is more successful than learning from static pictures* | 変化の単純特徴を学ぶ場合 $g = 0.340$、複雑特徴（加減速等）を学ぶ場合 $g = 0.647$。変化の特徴が学習目標でない場合 $g = 0.043$（静的図解と差なし）。（なお Castro-Alonso et al., 2019 でも全体 $g = 0.23$）。 | 「時間的変化・因果伝播・速度差」が本質でない静的配置比較はアニメーション化せず、静的図解や `interactive-explanation` に委ねる。 |
| **1. 教育アニメーションと認知モデル** | **Lowe & Boucheix (2008, 2016, 2017) / Ploetzner & Lowe (2012)** | *Animation Processing Model (APM)* / *Principled animation design improves comprehension of complex dynamics* | APM 5段階：(1) イベント単位への分解 → (2) 動的マイクロチャンク → (3) 因果連鎖 → (4) 機能エピソード → (5) メンタルモデル統合。**Compositional Approach**：分解済みの相互作用ペア（Relation Sets）を重複要素で連結提示するとメンタルモデル質と関係処理が有意向上（ただし局所運動学・転移課題では差なし）。 | 複雑な全体系を最初から同時に動かさない。要素単体 → 相互作用ペア（A+B → B+C）→ 全体統合の順に累積構築する。 |
| **1. 教育アニメーションと認知モデル** | **Boucheix & Lowe (2010) / Boucheix et al. (2013)** | *An eye tracking comparison of external pointing cues and internal continuous cues* / *Cueing animations* | 50 Hz アイトラッキング検証。外部静止矢印より内部連続キュー（Spreading-color / Progressive Path）が低顕著・高関連領域への視線誘導と理解度を向上。動的コントラスト強化、累積型（Snowballing）提示、イベント開始との時間同期が必須。 | 静止矢印の貼付に頼らず、因果パスに沿って色が伝播・蓄積する動的キュー（Progressive Path）を動作開始と厳密同期させる。 |
| **2. Data Videoとデザイン空間** | **Shi et al. (2021)** | *Communicating with Motion: A Design Space for Animated Visual Narratives in Data Videos* (CHI '21) | 82本のData Video分析。8大視覚物語戦略（Emphasis, Suspense, Comparison, Cohering, Ellipsis, Focalization, Concretization, Twist）と43モーション技法をデータ/視覚・カメラ・タイムラインの3層で整理。 | 各ビートに「8戦略のどれを担うか」の意図タグを必須付与し、データ層・カメラ層・タイムライン層の技法を対応づける。 |
| **2. Data Videoとデザイン空間** | **Amini et al. (2015, 2017)** | *Understanding Data Videos* (CHI '15) / *Authoring Data-Driven Videos with DataClips* (TVCG '17) | 50本分析：平均尺 3分（1–7.5分）、平均視覚化数 6（1–19）。映画的4構造 Establisher (E) / Initial (I) / Peak (P) / Release (R)、最頻出は `E+I+PR+`。9種の Attention Cues、70本超から抽出した7種の DataClip型。 | 解説全体を `E → I+ → P → R+` のアークで構成し、Initialで要素と問いを積み上げてPeakで核となる直観を解放する。 |
| **2. Data Videoとデザイン空間** | **Thompson, Liu, Li, & Stasko (2020, 2021)** | *Understanding the Design Space and Authoring Paradigms for Animated Data Graphics* (CGF '20) / *Data Animator* (CHI '21) | オブジェクト・グラフィック・データ・タイミングの4次元から10種の遷移タイプとペーシング技法を合成。キーフレーム／手続き型／プリセットの3パラダイムと状態間オブジェクト照合。 | 状態遷移を「オブジェクト対応表（`enter` / `update` / `exit`）」として明示的に定義し、対応のない要素の無理な補間を防ぐ。 |
| **2. Data Videoとデザイン空間** | **Heer & Robertson (2007)** | *Animated Transitions in Statistical Data Graphics* (InfoVis / TVCG '07) | 7遷移分類（View, Substrate, Filtering, Ordering, Timestep, Vis Change, Schema Change）。Congruence・Apprehension・Semantic Correspondence・Staging・Staggering。推奨遷移時間 約 1秒（実装 1.25秒、多段階 2秒）。実験1で Zoom & Filter ($p = 0.026$) 等は段階化優位だが、Timestep散布図では段階化が誤差増（$p = 0.002$）。 | 意味的対応が保たれる場合のみ連続変形し、スキーマ断絶時はディゾルブ／カットを使う。1段階遷移は `0.8–1.25秒`、多段階は `2秒` 以内に収める。 |
| **2. Data Videoとデザイン空間** | **Chevalier, Dragicevic, & Franconeri (2014)** | *The Not-so-Staggering Effect of Staggered Animated Transitions on Visual Tracking* (IEEE TVCG) | 2,560試行以上の実験（1秒・Slow-in/Slow-out基準）。要素開始をずらす Staggering の一般的な視覚追跡改善効果は実証されず、効用は限定的条件にとどまる。 | Staggering を「追跡容易化」の万能薬と誤認せず、導入時のリズム演出や順序提示に用途を限定する。 |
| **3. モーション原則・知覚・映画編集** | **Thomas & Johnston (1981) / Lasseter (1987) / Chang & Ungar (1993)** | *The Illusion of Life* / *Principles of Traditional Animation Applied to 3D* / *Animation: From Cartoons to the UI* | Staging（1瞬間に1つの明白な主題）、Anticipation（主動作前の短い予備動作）、Slow-in / Slow-out（2次・3次連続の加減速）、Arcs、Follow-through。UIでは実体性（Solidity）の維持が突然の出現による驚愕を防ぐ。 | 等速リニア移動を避け Slow-in/Slow-out を標準化。ただし Heer & Robertson (2007) に従い、数理・データ解説での誇張（Squash & Stretch）は意味歪曲のため原則禁止する。 |
| **3. モーション原則・知覚・映画編集** | **Bartram & Ware (2002) / Bartram, Ware, & Calvert (2003)** | *Filtering and Brushing with Motion* (InfoVis) / *Moticons* (IJHCS) | 動きの検出時間は約 1秒・周辺視野でも誤検出率ほぼ 0%（色は近傍 2.3秒/5.5%、周辺 4.6秒/24%）。Common Fate による強力グルーピング。方向差より運動種別差が識別容易（方向差は 90° 必要）。円運動は最も注意を奪う。 | 動きは周辺視野からも強制的に視線を奪うため、背景の装飾的ループや無関係な揺動を完全禁止する。並列グループ表現には同一運動パターン（Common Fate）を用いる。 |
| **3. モーション原則・知覚・映画編集** | **Pylyshyn & Storm (1988) / Cavanagh & Alvarez (2005) / Franconeri et al. (2010)** | *Tracking multiple independent targets* / *Tracking multiple targets with multifocal attention* | FINST理論：人間が独立して同時追跡できる移動対象は最大約 4個（片視野2個ずつ）。4個を超えると精度が急落し、移動中の個別識別・属性保持は極めて困難。間隔が狭すぎても崩壊。 | 独立軌道で同時移動する注目対象は原則 1〜2個（絶対上限 4個）に制限し、5個以上の要素は Common Fate で単一グループとして動かす。 |
| **3. モーション原則・知覚・映画編集** | **Tim J. Smith (2012) / Magliano & Zacks (2011) / Tang et al. (2020)** | *The Attentional Theory of Cinematic Continuity (AToCC)* / *Event Segmentation* / *Narrative Transitions in Data Videos* | 連続性は視聴者の視線と予測が構築する。180°ルール（空間配置の反転禁止）、Eye Trace（前シーンの注視点に次要素を配置）、Match-on-Action。行動の区切りがイベント境界を形成。7種のカメラ動作（Pan/Truck/Pedestal/Tilt/Dolly/Zoom/RackFocus）。 | シーン間でオブジェクトの左右・上下の空間対応を反転させない。同一空間内の視点移動はパン/ズームで連続性を保ち、視線移動距離を最小化する。 |
| **4. マルチメディア学習・同期・再生UI** | **Mayer (2009, 2020) / Mayer & Fiorella (2014, 2021, 2022)** | *Multimedia Learning* (3rd ed.) / *Cambridge Handbook of Multimedia Learning* | 転移効果量中央値：Coherence（無関係詳細の排除 $d = 1.66$、BGM排除 $d = 1.11$）、Multimedia $d = 1.35$、Temporal Contiguity $d = 1.22$（動画 1.31）、Redundancy $d = 0.86$、Pre-training $d = 0.85$、Segmenting $d = 0.67$、Modality $d = 0.65$。 | 無関係な演出・BGMを排除し、用語・構成要素の事前導入（Pre-training）と学習者制御のセグメント分割（Segmenting）を標準装備する。 |
| **4. マルチメディア学習・同期・再生UI** | **Spanjers et al. (2010, 2011, 2012) / 能動的休止研究 (2016)** | *Explaining the segmentation effect in learning from animations* (*Computers & Education*) 他 | 分節効果は「間（Pause）」と「時間的キュー」の協働で生じる。2秒 程度の短い休止でも内省に有効。ただし熟達者には強制休止が負荷となる（Expertise Reversal）。自由想起を伴う能動的休止は転移成績を有意向上（$\eta^2 = 0.314, p = 0.019$）。 | 各ビート末に `1.0–2.0秒` の定着ホールドを設けつつ、熟達者向けに即座に次ビートへスキップ／倍速再生できるUIを提供する。 |
| **4. マルチメディア学習・同期・再生UI** | **Netflix Timed Text Style Guides / BBC Subtitle Guidelines** | *Timed Text Style Guides (General / Japanese / English)* / *BBC Subtitle Guidelines* | Netflix公式日本語：標準上限 4 CPS・1行最大 13 全角文字・最小 500 ms（密集区分で上限 7 CPS・16 文字）。一般要件：最大2行・最小 833 ms（5/6秒）・最大 7秒。英語基準：一般安全目標 17 CPS（上限 20 CPS；BBC 160–180 WPM $\approx$ 15–18 CPS）、1行 37–42 文字。 | 無音Web解説のキャプション表示時間を文字数から自動算出し、読解完了前に重要モーションを開始しない安全マージンを強制する。 |
| **4. マルチメディア学習・同期・再生UI** | **Hundhausen, Douglas, & Stasko (2002) / Naps et al. (2002) / WCAG 2.2** | *A Meta-Study of AV Effectiveness* (JVLC) / *Engagement Taxonomy* (SIGCSE) / *WCAG 2.2 SC 2.3.3 & 2.2.2* | 24研究メタ分析：可視化の「見た目」より「学習者の関与方法」が成果を決定。巻き戻し不可の XTango（Stasko et al., 1993）は優位性なし。6段階関与分類（No Viewing → Viewing → Responding → Changing → Constructing → Presenting）。WCAG 2.3.3：前庭障害防止のため `prefers-reduced-motion` 対応と非必須モーション停止UIが必須。 | 再生シアターUIに「一時停止・1ビート戻し/送り・チャプターシーク・速度変更・モーション軽減モード」および任意の一問予測プロンプト（Responding）を組み込む。 |
| **5. トップ実践者メソッド** | **Grant Sanderson (3Blue1Brown / Manim) / Distill.pub / Kurzgesagt** | *3Blue1Brown About & Pedagogical Curse Lecture* / *Research Debt (2017)* / *Communicating with Interactive Articles (2020)* | Concrete before abstract、Never start with definitions（教育順 $\ne$ 論理順）、Avoid pointless animations、Leave room for an "aha!" moment、視覚的直観 → 数式変換の連続対応、階層的ディミング、緩急あるペーシング。 | 冒頭に定義や一般式を置かず、具体例と幾何学的直観から開始し、同一要素の連続モーフィングで数式・抽象構造へ橋渡しする。 |

---

## 2. 領域別の学術的ニュアンスと境界条件

- **APM と Compositional Approach の効用範囲（Lowe & Boucheix, 2008, 2016, 2017）**:
  - 学習者は動的情報を `(1) イベント単位への分解 → (2) 動的マイクロチャンク → (3) 因果連鎖 → (4) 機能エピソード → (5) メンタルモデル統合` の5段階で処理する。初心者は Phase 1 で「重要度」ではなく「大きく速く動く部品（視覚的顕著性）」に引きずられて分解に失敗する。
  - Compositional Approach（相互作用する2要素ペア Relation Sets を重複要素で橋渡ししながら累積構築）は、ピアノ機構の検証で**メンタルモデルの質と関係性を追う視線注視を有意に向上**させた。一方で**局所運動学の知識や転移課題スコア自体には有意差が見られておらず**、累積構築の主効用は「要素間の関係構造の統合」にある点に留意する。
  - 50 Hz アイトラッキング検証（Boucheix & Lowe, 2010; Boucheix et al., 2013）により、外部から指し示す静止矢印は動いている別部品に負けて見落とされやすく、要素内部から因果パスに沿って色が広がる **Spreading-color / Progressive Path** および累積型 **Snowballing（`A → A+B → A+B+C`）** をイベント開始と厳密同期させる必要性が示されている。
- **Data Video の物語文法と43技法（Amini et al., 2015, 2017; Shi et al., 2021）**:
  - Amini et al. (2015) の50本分析（平均尺 3分・1–7.5分、平均視覚化数 6・1–19）では、Cohn (2013) に基づく `E+I+PR+` が最頻出。映画物語と異なり **Initial が最も長く多くの視覚ユニットを費やして問いと事実を積み上げ**、Peak で一撃の洞察を解放し、Release で裏付けを行う。Amini et al. (2017) の DataClips では70本超から7種の基本クリップ型（Creation/Destruction, Cycling, Accumulating, Drill-down/Roll-up, Transition 等）を抽出。
  - Shi et al. (2021) は82本をデータ/視覚層・カメラ層・タイムライン層の3層（43技法）× 8大戦略（**Emphasis, Suspense, Comparison, Cohering, Ellipsis, Focalization, Concretization, Twist**）へ整理。実例では Emphasis が最頻出で、Focalization・Concretization・Twist は制作負荷が高く相対的に低頻度である。
- **Disney原則の厳格な取捨選択（Thomas & Johnston, 1981; Chang & Ungar, 1993; Heer & Robertson, 2007）**:
  - Chang & Ungar は UI 向けに Solidity（実体性）・Exaggeration（Anticipation）・Reinforcement（Slow-in/out, Arcs, Follow-through）を導入した。しかし数理・データ解説での **Squash & Stretch（押し潰しと伸縮）や過度な Exaggeration、無関係な Secondary Action は「意図せぬ意思・物理質量・誤った因果」を錯覚させるため禁止**（Heer & Robertson, 2007）。採用すべきは **Staging（同時に動かす主役は1つ）・2次/3次連続の Slow-in/Slow-out・抑制された Anticipation** に絞る。
- **運動知覚上限と映画編集の連続性（Bartram & Ware; Pylyshyn & Storm; Smith, 2012; Tang et al., 2020）**:
  - 動きの周辺視野検出率はほぼ誤検出 0%（約 1秒）であり、円運動は最も強く注意を奪うため、背景の常時回転や浮遊パーティクルは厳禁。方向差のみで別群と識別するには **90°** の角度差が必要（より確実には運動種別を変える）。
  - FINST 理論の独立追跡上限は **約 4個**（Cavanagh & Alvarez, 2005 によれば左右視野各 2個）だが、オブジェクト同士の間隔が狭い場合（Franconeri et al., 2010）や同一箇所を**毎秒 3回以上**通過する高密度移動では 4個未満でも追跡が崩壊し、ID・属性の保持も困難になる。
  - AToCC（Smith, 2012）の **180°ルール・Eye Trace・Match-on-Action**（同一シーン視点カットの約 1/4、急な動き開始に重なるカットの約 1/3 が意識されず通過）に従い空間迷子を防止。同一空間内は Tang et al. (2020) の7種カメラワーク（Pan / Truck / Pedestal / Tilt / Dolly / Zoom / RackFocus）で文脈を保ち、ディゾルブ多用による注意断片化・選好低下（$p < 0.001$）を避ける。
- **Temporal Contiguity のパラドックスと無音Webの制約**:
  - 音声あり動画では「語りながら動かす（Temporal Contiguity $d = 1.22$, 動画 $1.31$）」が有効だが、無音Web画面でテキストと動きを同時発生させると単一視覚チャネルで競合する（Modality $d = 0.65$、付随テキストなし $g = 0.883$ との乖離。なお Berney & Bétrancourt Table 3 には画面テキスト併用群の個別効果量は未収載だが、全体値 $g = 0.226$ との落差が文字併用による効果減衰を示唆する）。ゆえに Phase A（読解静止）と Phase C（主動作）の時分割が不可欠。
- **トップ実践者の演出哲学（Grant Sanderson / 3Blue1Brown, Distill.pub, Kurzgesagt）**:
  - 数学的論理順（定義 → 定理 → 例）と教育的順序（具体例 → 幾何直観 → 必然としての定義＝Definitions as endpoints）は逆転させる。「文字や数式をただ飛ばすだけのアニメーション（Pointless animations）」を排し、Write/Create による共創感・階層的ディミング・あえて間を残すことで視聴者自身に "Aha!" を譲る。

---

## 3. マクロ物語アーク：5幕構成（`E → I+ → P → R+`）仕様

全体尺は3分前後（**6〜10ビート程度**）を標準とし、以下の教育順で構築する。

| 幕 | フェーズ（尺目安・ビート数） | 認知・演出上の役割 | 必須ルール |
| :--- | :--- | :--- | :--- |
| **第1幕** | **Establisher**（10–15%・1–2ビート） | 問いと具体例の提示（Concrete before abstract） | 抽象定義・一般数式を置かない。「なぜ起きるか／どう解くか」の明確な問い（Tension）を1つの視覚シーンで立てる。 |
| **第2幕** | **Initial-A**（20–25%・2ビート） | 要素導入と事前学習（Pre-training, $d = 0.85$） | 登場する主役オブジェクト（ノード・ベクトル・座標軸・変数）を少数ずつ Draw-on で導入し、色・形と意味の対応を確立する。まだ全体系を稼働させない。 |
| **第3幕** | **Initial-B**（30–35%・2–3ビート） | 因果の累積構築と展開（Compositional Build） | 最小ペア `A+B` を Progressive Path で示し、共通要素 `B` を介して `B+C` へ拡張する。反復は初回1–2回を丁寧に、3回目以降は Ellipsis で加速圧縮し期待（Suspense）を高める。 |
| **第4幕** | **Peak**（15–20%・1–2ビート） | 核となる「Aha!」の解放 | 直前に `1.5–2.0s` の意図的な間（または任意の Responding 予測プロンプト）を置き、モーフィング・ズームアウト・数式一致を一撃で実行する。直後に最低 `2.0s`（`1800–2500 ms`）の余韻ホールドを確保する。 |
| **第5幕** | **Release**（15–20%・1–2ビート） | 一般化・抽象化・要約定着（Definitions as endpoints） | Peak で獲得した視覚構造と色対応させて初めて正式な定義・一般数式・計算量を提示する。最後に全体の関係図を静止俯瞰ビューとして提示し、任意ビートへ戻れる状態で完了する。 |

---

## 4. 解説意図別「モーション語彙・デザイン空間」10パターン完全マッピング表

> [!NOTE]
> 下表の遷移時間（約 `1秒`・`1.25秒`・多段階 `2秒`）、同時追跡上限（`4個`）、方向差（`90°`）、定着休止（`1–2秒`）は一次論文の実測・推奨値に基づき、CSSベジェ係数・ディミング透過率（`0.15–0.25`）・Stagger 刻み（`80–150 ms`）等はそれら認知制約をWeb UI実装へ翻訳した設計推奨値である。

| # | 解説意図 | 推奨モーション技法（語彙） | タイミング・イージング・同時動作数ガイドライン | 認知的効果と一次ソース根拠 |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **構成要素の段階的導入**<br>（Pre-training / 概念の土台作り） | `Draw-on`（線描） / `Progressive Reveal` / `Staggered Entry`<br>（座標軸 → 目盛 → 代表要素の順に累積出現） | ・単体出現：`400–700 ms`<br>・要素間 Stagger 間隔：`80–150 ms`（全体 $\le 1.5\text{ s}$）<br>・イージング：`cubic-bezier(0.22, 1, 0.36, 1)`（Ease-out）<br>・同時導入：1 概念グループずつ | 学習者に要素の名称と役割を事前定着させ（Pre-training, $d = 0.85$）、視聴者と共創する感覚を生む。Stagger は追跡補助ではなく順序構造の視覚化に限定使用（Chevalier et al., 2014）。 |
| **2** | **構造の分解・組立**<br>（Compositional Build / 関係セット連結） | `Accumulating` / `Relation-Set Highlight` + `Sequential Assemble`<br>（`A+B` の相互作用 → 共通要素 `B` を残し `B+C` を接続 → 全体統合） | ・各関係セット提示：`800–1200 ms`<br>・セット間ホールド：`1000–1500 ms`<br>・イージング：`cubic-bezier(0.4, 0, 0.2, 1)`（Slow-in/Slow-out）<br>・同時稼働ペア：2要素（最大 1 ペア/ビート） | 初心者が失敗しやすい APM Phase 1（全体分解）をスキップさせ、ワーキングメモリ上限内で Phase 2〜3 の関係処理を直接促進する（Lowe & Boucheix, 2016, 2017）。 |
| **3** | **因果・データフローの伝播**<br>（アルゴリズム実行・信号伝達） | `Progressive Path Cue`（内部連続色伝播） / `Follow-Path Token` / `Snowballing Trail`<br>（静止矢印ではなく経路自体が発光・進行し履歴を残す） | ・パス伝播速度：視線追跡可能な定常〜緩やかな Slow-in/out（`800–1500 ms`/ホップ）<br>・発火前の予備点灯（Anticipation）：`150–250 ms`<br>・同時稼働トークン：独立軌道 1〜2個（絶対上限 4個） | 外部矢印より低顕著・高関連箇所への視線到達率と理解度が高く（Boucheix & Lowe, 2010）、履歴（History）の保持が動的時系列タスク性能を約 `1.49` 倍改善する（IEEE TVCG 2025）。 |
| **4** | **数式と幾何学的直観の対応付け**<br>（Visual-First → Formula-Second） | `Color-Coded Matching Morph` / `Split-and-Map`<br>（幾何領域・ベクトルを色付け → 対応する数式項を同色で抽出・変形・置換） | ・幾何直観の提示 → ホールド `1500 ms` → 数式出現 `600 ms` → 対応変形 `1000–1250 ms`<br>・イージング：Cubic Slow-in/Slow-out<br>・同時変形対象：1 項（または同一変換を受ける 1 群） | 定義先行を避け（Sanderson原則）、意味的対応（Semantic Correspondence）を視覚的に保証することで記号と空間モデルの統合を促す（Heer & Robertson, 2007）。 |
| **5** | **抽象度のズームイン／アウト**<br>（詳細ドリルダウンと全体文脈の維持） | `Continuous Camera Zoom & Pan`（Dolly / Truck / Drill-down & Roll-up）<br>（局所へ寄る前に全体枠を一瞬強調し、滑らかにズームイン → 再び引いて文脈復帰） | ・カメラ移動：`900–1400 ms`（距離が大きい場合は最大 `1800 ms`）<br>・イージング：強めの Slow-in/Slow-out（`cubic-bezier(0.65, 0, 0.35, 1)`）<br>・ズーム中のオブジェクト変形：`0`（Staging厳守） | 空間的連続性を保ちつつ「全体の中のどこを見ているか」の空間迷子を防ぐ（Shi et al., 2021; Smith, 2012）。ただし前庭負荷が高いため `prefers-reduced-motion` 時は穏やかなフェードへ置換（WCAG 2.2 SC 2.3.3）。 |
| **6** | **重要箇所の強調と背景抑制**<br>（Emphasis / Focalization） | `Spotlight Highlight-Dim` / `Scale-Subtle` / `Dynamic Pulse`<br>（主役を彩度・明度強調し、非関連要素の `opacity` を `0.15–0.25` へ同時減光） | ・ディミング遷移：`250–400 ms`（Ease-out）<br>・動的パルス（必要時のみ）：1回 のみ `400–600 ms`（無限ループ厳禁）<br>・強調対象：1 要素または 1 意味グループ | 視覚的顕著性とテーマ的重要度のズレを解消し（Boucheix & Lowe, 2010）、Shi et al. (2021) で最頻出の Emphasis 戦略を視覚ノイズ最小で実現する。 |
| **7** | **状態・表現視点の切替**<br>（View / Encoding / Schema Transformation） | `Staged Morph`（同一データ集合） vs `Clean Cut / Cross-Dissolve`（スキーマ断絶時）<br>（例：散布図 → X軸整列 → 棒へ変形） | ・単段階遷移：`800–1250 ms`<br>・2段階 Staged 遷移：各段階 `800–900 ms` ＋段階間静止 `300–500 ms`（合計約 `2.0 s`）<br>・ディゾルブ：`350–500 ms`<br>・イージング：Cubic Slow-in/Slow-out | 同一要素の視点転換では Staged 遷移が追跡誤差と変化量推定誤差を有意低減する。無関係なグラフ間はディゾルブ／カットで偽の関連を防ぐ（Heer & Robertson, 2007）。 |
| **8** | **並列プロセス・集合挙動の表現**<br>（Concretization / 集団統計・並列計算） | `Common Fate Bundling` / `Concretization Merge`<br>（多数の粒子・データ点を同一速度・同一軌道群として束ねて動かし、ヒストグラムや分布へ合流） | ・移動：`1000–1500 ms`、合流変形：`600–800 ms`<br>・イージング：Slow-in/Slow-out<br>・独立グループ数：最大 2〜3群（異なる軌道方向は可能な限り $\ge 90^\circ$ 離すか運動種別を変える） | 個別追跡上限（4個）を超える要素群をゲシュタルトの Common Fate で単一知覚ユニットへ圧縮し、生データから高次構造への具体化を直観化（Bartram & Ware, 2002; Shi et al., 2021）。 |
| **9** | **予測喚起・緊張と「Aha!」の開示**<br>（Suspense / Twist / Peak） | `Gradual Reveal` / `Count-Up` / `Tension Pause` → `Dramatic Reveal`<br>（途中まで描いて静止し予測させ、一瞬の間を置いて真の構造や反転を一気に展開） | ・期待形成（Gradual Reveal）：`1000–1500 ms`<br>・意図的な間（Tension Pause）：`1500–2000 ms`（またはユーザー操作待ち）<br>・Peak 開示：`600–1000 ms`（明快な Ease-out）＋余韻 `2000 ms` | Suspense と Twist を分離設計し（Shi et al., 2021）、Sanderson の「Aha!の余白」と Naps et al. (2002) の Responding 関与を同時達成する。 |
| **10** | **自明な反復の省略・時間圧縮**<br>（Ellipsis / Fast-Forward） | `Speed-Up Compression` / `Step-Skip Indicator`<br>（最初の1〜2反復を等速で丁寧に見せた後、3回目以降を加速して収束状態へ一気に進める） | ・丁寧な初回反復：通常速度（各 `1000–1500 ms`）<br>・圧縮反復：`3x–6x` 加速（例：`150–250 ms`/回、合計 $\le 2.0\text{ s}$）＋進捗カウンタ表示<br>・最終収束時に減速停止（Slow-out `500 ms`） | Shi et al. (2021) の Ellipsis 戦略。反復アルゴリズム（勾配降下法・ソート等）で冗長による集中離脱を防ぎつつ、プロセスの連続性と収束を両立する。 |

---

## 5. モーション選択における3つの重要トレードオフ（LLM判断ルール）

1. **Staging（段階化）すべき遷移 vs Direct（直接）動かす遷移**
   - 座標軸スケーリング＋フィルタリングや、散布図→棒グラフへの表現変更（Visualization Change）では、「軸変更 → マーク変形」と段階分離する方が追跡精度が高い（Heer & Robertson, 2007 実験1：Zoom & Filter $p = 0.026$、Sort Bars $p = 0.051$、Bar to Donut $p = 0.071$）。
   - しかし **Timestep 散布図（X軸・Y軸が同時変化する時系列移動）** やベクトルの回転・合成のように2変数の同時変化そのものが物理的・数理的意味を持つ場合は、**X方向とY方向に段階分離してはならない**（実験1で直接移動より有意に誤差増加、$p = 0.002$）。また複数時系列ラインを1本ずつ順に出す段階化も条件により性能を低下させ得る点に留意する。
   - **Staggering** は視覚追跡改善の万能薬ではない（Chevalier et al., 2014 の 2,560試行超で一般効果なし）ため、順序導入（`Draw-on`）のリズム演出に用途を限定する。
2. **連続モーフィング（Morph） vs カット／ディゾルブ（Cut / Dissolve）**
   - モーフィングは視聴者の脳に「変形前と変形後は同一の存在である」という強力な意味的同一性（Object Permanence）を刷り込む。
   - 数式の等価変形や同一データ点の別表現変換には連続補間を使い、**別概念・別データ集合・スキーマ断絶の遷移では SVG パスを無理に補間せず `350–500 ms` のクリーンなディゾルブまたは明示的カット**を用いる。
3. **軌跡（Trace）と履歴（History）の残存**
   - アニメーション最大の弱点は過去のフレームが消える「揮発性（Transience）」にある。動的時系列の知覚実験（IEEE TVCG 2025）では、履歴の保持がタスク性能を **1.49倍** 改善し、軌跡（Trace）と履歴（History）の併用が理解と選好を共に高めることが示されている。
   - 探索経路・最適化軌跡・状態遷移の変化前シルエットは、直前の状態を薄い残像（`opacity: 0.15–0.25`）や細い軌跡線としてキャンバス上に残し、比較容易性を担保する。
