# 解説アニメーション 実装パターン集（HTML / SVG / Canvas / CSS / JS）

本ドキュメントは、無音Web環境におけるマイクロペーシング・決定論的ビート制御・シアターUI・アクセシビリティ・マルチ環境（Claude Artifacts / ローカルブラウザ / Antigravity）互換のテーマ連携を満たすための、**ゼロ依存（外部CDN不要・Vanilla CSS）**で再利用可能な実装パターンを提供する。

---

## 1. 無音マイクロペーシング自動計算＋決定論的ビートタイムライン・エンジン

**目的**: `setTimeout` 連鎖や不可逆な CSS `@keyframes` を排除し、単一の時刻状態 `tMs` から全ビート・全フェーズ（Phase A〜E）の補間係数を純粋計算する（Gotcha #2, #6, #7, #8 回避）。

```javascript
/**
 * 言語別の放送字幕規格に基づく Phase A（読解静止時間）の自動算出
 * - 日本語: 4.0 CPS（推奨 1000ms〜7000ms）
 * - 英語  : 17.0 CPS（Netflix一般目標、最小 833ms〜最大 7000ms）
 */
function calcReadingDwellMs(caption, lang = 'ja') {
  const cleanLength = caption.replace(/\s+/g, '').length;
  if (lang === 'en') {
    const raw = (caption.trim().length / 17.0) * 1000;
    return Math.round(Math.max(833, Math.min(7000, raw)));
  }
  const raw = (cleanLength / 4.0) * 1000;
  return Math.round(Math.max(1000, Math.min(7000, raw)));
}

/** 2次・3次連続の Slow-in / Slow-out イージング群（linear の乱用を防止） */
const EASING = {
  outCubic: (t) => 1 - Math.pow(1 - t, 3),
  inOutCubic: (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
  // カメラワーク（Dolly / Zoom / Pan）用の強めの Slow-in/Slow-out: cubic-bezier(0.65, 0, 0.35, 1) 近似
  camera: (t) => (t < 0.5 ? 8 * t * t * t * t : 1 - Math.pow(-2 * t + 2, 4) / 2),
};

const clamp01 = (v) => Math.max(0, Math.min(1, v));

/**
 * ビート定義配列から累積タイムラインを構築する
 * beat: { id, act, strategy, caption, lang, cueMs, motionMs, holdMs, boundaryMs, checkpoint }
 */
function buildTimeline(beats) {
  let cursor = 0;
  const compiled = beats.map((b, index) => {
    const phaseAMs = calcReadingDwellMs(b.caption, b.lang ?? 'ja');
    const phaseBMs = Math.max(200, Math.min(400, b.cueMs ?? 300));
    const phaseCMs = Math.max(400, Math.min(2000, b.motionMs ?? 1000));
    // Peak は最低 1800ms、通常ビートは最低 1000ms の定着ホールドを強制
    const minHold = b.act === 'Peak' ? 1800 : 1000;
    const phaseDMs = Math.max(minHold, b.holdMs ?? (b.act === 'Peak' ? 2000 : 1200));
    // Phase E: 最小2フレーム（>= 33ms）以上のビート境界
    const phaseEMs = Math.max(40, b.boundaryMs ?? 60);
    const totalMs = phaseAMs + phaseBMs + phaseCMs + phaseDMs + phaseEMs;

    const entry = {
      ...b,
      index,
      startMs: cursor,
      endMs: cursor + totalMs,
      durations: { phaseAMs, phaseBMs, phaseCMs, phaseDMs, phaseEMs, totalMs },
    };
    cursor += totalMs;
    return entry;
  });

  return { beats: compiled, totalMs: cursor };
}

/**
 * 任意の現在時刻 tMs から描画用フレーム状態を純粋計算する（シーク／巻き戻しで100%決定論的）
 */
function evaluateTimeline(timeline, tMs, reducedMotion = false) {
  const clampedMs = Math.max(0, Math.min(timeline.totalMs, tMs));
  const beat =
    timeline.beats.find((b) => clampedMs < b.endMs) ??
    timeline.beats[timeline.beats.length - 1];
  const localMs = clampedMs - beat.startMs;
  const { phaseAMs, phaseBMs, phaseCMs, phaseDMs, phaseEMs } = beat.durations;

  const bStart = phaseAMs;
  const cStart = bStart + phaseBMs;
  const dStart = cStart + phaseCMs;
  const eStart = dStart + phaseDMs;

  let phase = 'A';
  let phaseT = 0;
  let cueT = 0;
  let motionT = 0;

  if (localMs < bStart) {
    phase = 'A';
    phaseT = clamp01(localMs / phaseAMs);
  } else if (localMs < cStart) {
    phase = 'B';
    phaseT = clamp01((localMs - bStart) / phaseBMs);
    cueT = EASING.outCubic(phaseT);
  } else if (localMs < dStart) {
    phase = 'C';
    phaseT = clamp01((localMs - cStart) / phaseCMs);
    cueT = 1;
    // モーション軽減時は Phase C 冒頭 200ms の静かなフェードで即座に最終状態へ切り替え
    motionT = reducedMotion
      ? clamp01((localMs - cStart) / Math.min(200, phaseCMs))
      : EASING.inOutCubic(phaseT);
  } else if (localMs < eStart) {
    phase = 'D';
    phaseT = clamp01((localMs - dStart) / phaseDMs);
    cueT = 1;
    motionT = 1;
  } else {
    phase = 'E';
    phaseT = clamp01((localMs - eStart) / phaseEMs);
    cueT = 1;
    motionT = 1;
  }

  // 非注目要素のディミング透過率（Phase B で 1.0 → 0.20 へ減光し、Phase D 後半まで維持）
  const dimOpacity = 1 - 0.8 * cueT;

  return {
    tMs: clampedMs,
    beatIndex: beat.index,
    beat,
    phase,
    phaseT,
    cueT,
    motionT,
    dimOpacity,
    reducedMotion,
  };
}
```

---

## 2. 再生シアターUIコントロール＆キーボード操作

**目的**: 1ビート戻し/送り・現在ビート再再生・幕＆ビート境界付きシークバー・速度切替（`0.5x–2.0x`）・自動/手動ステップ切替を標準搭載する（Hundhausen et al., 2002; Spanjers et al., 2011）。

```html
<!-- シアターUIコントロールバー（Vanilla CSS + セマンティック変数準拠） -->
<div class="theater-controls">
  <!-- ビート構造化シークバー（幕ラベル＋ビート境界マーカー） -->
  <div id="scrubber-track" class="scrubber-track" role="slider" aria-label="タイムラインシーク">
    <div class="scrubber-rail">
      <div id="scrubber-fill" class="scrubber-fill" style="width: 0%"></div>
    </div>
    <div id="scrubber-markers" class="scrubber-markers"></div>
  </div>

  <!-- 操作ボタン群 -->
  <div class="theater-bar">
    <div class="theater-group">
      <button id="btn-prev" type="button" title="1ビート戻る (←)" class="theater-btn">◀ 前ビート</button>
      <button id="btn-replay" type="button" title="このビートを最初から (R)" class="theater-btn">↺ 再再生</button>
      <button id="btn-play" type="button" title="再生 / 一時停止 (Space)" class="theater-btn theater-btn--primary">▶ 再生</button>
      <button id="btn-next" type="button" title="1ビート進む (→)" class="theater-btn">次ビート ▶</button>
      <span id="beat-readout" class="theater-readout">1 / 6 [E]</span>
    </div>

    <div class="theater-group">
      <select id="speed-select" aria-label="再生速度" class="theater-select">
        <option value="0.5">0.5x</option>
        <option value="1" selected>1.0x</option>
        <option value="1.5">1.5x</option>
        <option value="2">2.0x</option>
      </select>
      <button id="btn-step-mode" type="button" class="theater-btn">モード: 連続</button>
      <button id="btn-reduced" type="button" aria-pressed="false" class="theater-btn">モーション軽減: OFF</button>
    </div>
  </div>
</div>
```

```javascript
function attachTheaterControls(timeline, state, onSeek, onTogglePlay, onRender) {
  const markersEl = document.getElementById('scrubber-markers');
  timeline.beats.forEach((b, i) => {
    if (i === 0) return;
    const leftPct = (b.startMs / timeline.totalMs) * 100;
    const tick = document.createElement('span');
    tick.className = 'scrubber-tick';
    tick.style.left = `${leftPct}%`;
    tick.title = `Beat ${i + 1} (${b.act})`;
    markersEl.appendChild(tick);
  });

  const track = document.getElementById('scrubber-track');
  const seekFromPointer = (clientX) => {
    const rect = track.getBoundingClientRect();
    const ratio = clamp01((clientX - rect.left) / rect.width);
    onSeek(ratio * timeline.totalMs);
  };
  track.addEventListener('pointerdown', (e) => {
    track.setPointerCapture(e.pointerId);
    seekFromPointer(e.clientX);
  });
  track.addEventListener('pointermove', (e) => {
    if (track.hasPointerCapture(e.pointerId)) seekFromPointer(e.clientX);
  });

  const jumpToBeat = (targetIdx) => {
    const idx = Math.max(0, Math.min(timeline.beats.length - 1, targetIdx));
    onSeek(timeline.beats[idx].startMs);
  };

  document.getElementById('btn-prev').addEventListener('click', () => {
    const cur = evaluateTimeline(timeline, state.tMs, state.reducedMotion);
    // ビート開始から少し進んでいたら頭出し、開始直後なら前ビートへ
    const elapsedInBeat = state.tMs - cur.beat.startMs;
    jumpToBeat(elapsedInBeat > 400 ? cur.beatIndex : cur.beatIndex - 1);
  });
  document.getElementById('btn-replay').addEventListener('click', () => {
    const cur = evaluateTimeline(timeline, state.tMs, state.reducedMotion);
    jumpToBeat(cur.beatIndex);
    if (!state.playing) onTogglePlay(true);
  });
  document.getElementById('btn-next').addEventListener('click', () => {
    const cur = evaluateTimeline(timeline, state.tMs, state.reducedMotion);
    jumpToBeat(cur.beatIndex + 1);
  });
  document.getElementById('btn-play').addEventListener('click', () => onTogglePlay());

  document.getElementById('speed-select').addEventListener('change', (e) => {
    state.speed = parseFloat(e.target.value);
  });

  const stepBtn = document.getElementById('btn-step-mode');
  stepBtn.addEventListener('click', () => {
    state.manualStep = !state.manualStep;
    stepBtn.textContent = `モード: ${state.manualStep ? '1ビート停止' : '連続'}`;
  });

  // キーボード操作（Space / ArrowLeft / ArrowRight / R）
  window.addEventListener('keydown', (e) => {
    if (['INPUT', 'TEXTAREA', 'SELECT'].includes(e.target.tagName)) return;
    if (e.code === 'Space') { e.preventDefault(); onTogglePlay(); }
    else if (e.code === 'ArrowLeft') { e.preventDefault(); document.getElementById('btn-prev').click(); }
    else if (e.code === 'ArrowRight') { e.preventDefault(); document.getElementById('btn-next').click(); }
    else if (e.key === 'r' || e.key === 'R') { e.preventDefault(); document.getElementById('btn-replay').click(); }
  });
}
```

---

## 3. Peak直前の任意「能動的休止（Responding Checkpoint）」パターン

**目的**: 熟達者逆転効果（Spanjers et al., 2011）に配慮してオン/オフ切替を可能にしつつ、Peak直前で1問だけの予測選択（Naps et al., 2002; $\eta^2 = 0.314$）を挿入して「Aha!」の認知的定着を最大化する。

```javascript
/**
 * requestAnimationFrame ループ内でビート境界(Phase E)到達を検知し、
 * checkpoint 対象ビートかつ設定ONなら自動停止して予測プロンプトを表示する
 */
function handleCheckpointGate(frame, state, onPause, showPromptUI) {
  if (!state.checkpointsEnabled) return false;
  const cp = frame.beat.checkpoint;
  if (!cp || state.answeredCheckpoints.has(frame.beat.id)) return false;

  if (frame.phase === 'E' && state.playing) {
    onPause();
    showPromptUI(cp, (chosenOptionId) => {
      state.answeredCheckpoints.add(frame.beat.id);
      // 回答後、即時1行フィードバックを表示してから次ビート（Peak）を再生開始
      return cp.feedback[chosenOptionId];
    });
    return true;
  }
  return false;
}
```

---

## 4. Progressive Path（内部連続色伝播）＋ ディミング ＋ 残像履歴（Trace/History）

**目的**: 外部静止矢印の貼付に頼らず因果パスに沿って色が伝播する動的キュー（Boucheix & Lowe, 2010）を実装し、さらに比較用の直前状態残像（`opacity: 0.18`）を残す（IEEE TVCG 2025）。

```html
<svg id="stage" viewBox="0 0 560 220" class="stage-svg">
  <!-- Layer 1: 比較用の残像・履歴レイヤー（直前状態シルエットを薄く保持） -->
  <g id="layer-history" opacity="0.18" style="color: var(--ui-muted)"></g>

  <!-- Layer 2: 非注目コンテキスト（Phase B で dimOpacity へ減光） -->
  <g id="layer-context" style="color: var(--ui-muted)"></g>

  <!-- Layer 3: 因果パス（下地レール ＋ Progressive Path 発光オーバーレイ） -->
  <path id="flow-rail" d="M 80 110 C 200 30, 360 190, 480 110"
        fill="none" stroke="var(--ui-border)" stroke-width="4" stroke-linecap="round" />
  <path id="flow-active" d="M 80 110 C 200 30, 360 190, 480 110"
        fill="none" stroke="var(--ui-c1)" stroke-width="5" stroke-linecap="round" />

  <!-- Layer 4: 主役ノード（セマンティックカラーでキャプション・数式と統一） -->
  <circle id="actor-a" cx="80" cy="110" r="14" fill="var(--ui-c1)" />
  <circle id="actor-b" cx="480" cy="110" r="14" fill="var(--ui-c2)" />
</svg>

<script>
/**
 * Progressive Path を motionT ∈ [0, 1] から純粋計算で描画する
 */
function renderProgressivePath(pathEl, motionT) {
  const len = pathEl.getTotalLength();
  pathEl.style.strokeDasharray = `${len}`;
  pathEl.style.strokeDashoffset = `${len * (1 - clamp01(motionT))}`;
}

/**
 * 1フレーム描画の統合例（ディミング + 予備点灯 + Progressive Path）
 */
function renderFlowBeat(frame) {
  const pathEl = document.getElementById('flow-active');
  const ctxLayer = document.getElementById('layer-context');
  const actorA = document.getElementById('actor-a');

  // Phase B の視線誘導：非関連要素の減光 & 発火元ノードの控えめな予備点灯（Anticipation）
  ctxLayer.setAttribute('opacity', frame.dimOpacity.toFixed(3));
  const anticipationScale = frame.reducedMotion
    ? 1
    : 1 + 0.14 * Math.sin(Math.PI * frame.cueT) * (frame.phase === 'B' ? 1 : 0);
  actorA.setAttribute('transform', `translate(80,110) scale(${anticipationScale.toFixed(3)}) translate(-80,-110)`);

  // Phase C の主動作：因果パスの連続色伝播（動作開始と厳密同期）
  renderProgressivePath(pathEl, frame.motionT);
}
</script>
```

---

## 5. 意味的対応（`enter / update / exit` IDマップ）と SVG `viewBox` 連続カメラワーク

**目的**: 同一エンティティのみを補間し（Heer & Robertson, 2007; Thompson et al., 2021）、カメラ移動中はデータ変形を行わない（Staging）ことで空間迷子を防ぐ。

```javascript
const lerp = (a, b, t) => a + (b - a) * t;

/**
 * ビート間のオブジェクト状態辞書を比較し、enter / update / exit を自動分離して補間する
 * prevEntities / nextEntities: Record<id, { x, y, r, color }>
 */
function interpolateEntities(prevEntities, nextEntities, motionT, isSchemaBreak = false) {
  const result = {};
  const allIds = new Set([...Object.keys(prevEntities), ...Object.keys(nextEntities)]);

  allIds.forEach((id) => {
    const prev = prevEntities[id];
    const next = nextEntities[id];

    if (prev && next && !isSchemaBreak) {
      // update: 意味的対応が保たれている同一エンティティのみ連続補間
      result[id] = {
        mode: 'update',
        x: lerp(prev.x, next.x, motionT),
        y: lerp(prev.y, next.y, motionT),
        r: lerp(prev.r, next.r, motionT),
        opacity: 1,
        color: motionT < 0.5 ? prev.color : next.color,
      };
    } else if (next && !prev) {
      // enter: 新規出現は 350–500ms 相当のクリーンなフェードイン
      result[id] = { ...next, mode: 'enter', opacity: clamp01(motionT / 0.45) };
    } else if (prev && !next) {
      // exit: 退場はクリーンなフェードアウト
      result[id] = { ...prev, mode: 'exit', opacity: clamp01(1 - motionT / 0.45) };
    } else {
      // スキーマ断絶時（isSchemaBreak=true）は無理な変形をせずクロスディゾルブ
      const useNext = motionT >= 0.5;
      const alpha = Math.abs(motionT - 0.5) * 2;
      result[id] = { ...(useNext ? next : prev), mode: 'dissolve', opacity: clamp01(alpha) };
    }
  });
  return result;
}

/**
 * SVG viewBox による連続カメラ移動（ズーム／パン専用ビートで実行し、データ変形とは分離する）
 * viewBox = [x, y, width, height]
 */
function applyCameraViewBox(svgEl, fromBox, toBox, rawPhaseT, reducedMotion) {
  if (reducedMotion) {
    // WCAG 2.2 SC 2.3.3: 前庭負荷回避のため連続ズームはせず、切り替わり後のフレームを静止表示
    const box = rawPhaseT > 0.1 ? toBox : fromBox;
    svgEl.setAttribute('viewBox', box.join(' '));
    return;
  }
  const t = EASING.camera(clamp01(rawPhaseT));
  const current = [0, 1, 2, 3].map((i) => lerp(fromBox[i], toBox[i], t).toFixed(2));
  svgEl.setAttribute('viewBox', current.join(' '));
}
```

---

## 6. `prefers-reduced-motion: reduce` 自動検知＋手動「モーション軽減」トグル

**目的**: WCAG 2.2 SC 2.3.3 に準拠し、OS設定の自動追従とUI上の明示的トグルを両立する。

```javascript
function initReducedMotionController(state, toggleBtn, onChange) {
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
  let manualOverride = null; // null なら OS 設定に追従

  const sync = () => {
    state.reducedMotion = manualOverride !== null ? manualOverride : mq.matches;
    toggleBtn.setAttribute('aria-pressed', String(state.reducedMotion));
    toggleBtn.textContent = `モーション軽減: ${state.reducedMotion ? 'ON' : 'OFF'}`;
    onChange(state.reducedMotion);
  };

  mq.addEventListener('change', sync);
  toggleBtn.addEventListener('click', () => {
    manualOverride = !(manualOverride !== null ? manualOverride : mq.matches);
    sync();
  });

  sync();
}
```

---

## 7. マルチ環境対応 Vanilla CSS ベーステンプレート＆ Canvas ライブテーマ再描画

**目的**: Claude Artifacts、Claude Code（ローカルHTML）、スタンドアロンブラウザ、および Antigravity（`generative_ui`）の全環境で外部CDNなしにそのまま動作し、ライト/ダークのライブテーマ切替でも状態を保ったまま再描画する最小HTML骨格（Antigravity の `<agent-embed>` インライン埋め込み時は `<body class="is-inline">` で `background: transparent; padding: 0`、高さ `<= 450px` 予算に適合）。

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <style>
    :root {
      color-scheme: light dark;
      /* ホスト注入トークン（Antigravity等）があれば優先継承し、未定義環境（Claude Artifacts / 単体ブラウザ）では light-dark() で自動適応。
         ※ホスト変数を上書きしないよう --background / --card 等自体は :root に再定義しない */
      --ui-bg: var(--background, light-dark(#f8fafc, #09090b));
      --ui-surface: var(--card, light-dark(#ffffff, #18181b));
      --ui-surface-2: var(--secondary, light-dark(#f1f5f9, #27272a));
      --ui-fg: var(--foreground, light-dark(#0f172a, #f4f4f5));
      --ui-muted: var(--muted-foreground, light-dark(#64748b, #a1a1aa));
      --ui-border: var(--border, light-dark(#cbd5e1, #3f3f46));
      --ui-card-border: var(--card-border, var(--ui-border));
      --ui-primary: var(--primary, light-dark(#2563eb, #3b82f6));
      --ui-primary-fg: var(--primary-foreground, #ffffff);
      --ui-c1: var(--chart-1, light-dark(#2563eb, #60a5fa));
      --ui-c2: var(--chart-2, light-dark(#059669, #34d399));
      --ui-c3: var(--chart-3, light-dark(#d97706, #fbbf24));
      --ui-c4: var(--chart-4, light-dark(#e11d48, #fb7185));
    }
    html.light { color-scheme: light; }
    html.dark { color-scheme: dark; }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 16px;
      background: var(--ui-bg);
      color: var(--ui-fg);
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    /* Antigravity インライン埋め込み時は <body class="is-inline"> で背景透過・余白ゼロ */
    body.is-inline { background: transparent; padding: 0; }

    .theater-shell { max-width: 48rem; margin: 0 auto; display: flex; flex-direction: column; gap: 10px; padding: 8px 0; }
    .stage-card { border-radius: 8px; border: 1px solid var(--ui-card-border); background: var(--ui-surface); padding: 12px; }
    .stage-canvas, .stage-svg { width: 100%; height: auto; display: block; }
    .caption-box { margin-top: 8px; padding-top: 8px; border-top: 1px solid var(--ui-card-border); min-height: 2.75rem; display: flex; align-items: center; justify-content: center; text-align: center; }
    .caption-text { margin: 0; font-size: 0.875rem; font-weight: 500; line-height: 1.375; color: var(--ui-fg); }

    /* Section 2 シアターUIコントロールバー用スタイル */
    .theater-controls { display: flex; flex-direction: column; gap: 8px; padding-top: 8px; border-top: 1px solid var(--ui-card-border); font-size: 0.75rem; }
    .scrubber-track { position: relative; height: 20px; display: flex; align-items: center; cursor: pointer; user-select: none; }
    .scrubber-rail { position: relative; width: 100%; height: 6px; border-radius: 9999px; background: var(--ui-border); overflow: hidden; }
    .scrubber-fill { height: 100%; background: var(--ui-primary); }
    .scrubber-markers { position: absolute; inset: 0; pointer-events: none; }
    .scrubber-tick { position: absolute; top: 4px; bottom: 4px; width: 1px; background: var(--ui-fg); opacity: 0.35; }
    .theater-bar { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px; }
    .theater-group { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }
    .theater-btn, .theater-select {
      padding: 4px 8px; border-radius: 6px; border: 1px solid var(--ui-border);
      background: var(--ui-surface); color: var(--ui-fg); font-size: inherit; cursor: pointer;
    }
    .theater-btn:hover { background: var(--ui-surface-2); }
    .theater-btn--primary { padding: 4px 12px; background: var(--ui-primary); color: var(--ui-primary-fg); border-color: transparent; font-weight: 500; }
    .theater-btn--primary:hover { filter: brightness(1.08); background: var(--ui-primary); }
    .theater-readout { margin-left: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-variant-numeric: tabular-nums; color: var(--ui-muted); }
  </style>
</head>
<body>
  <div class="theater-shell">
    <!-- ステージ領域（インライン埋め込み時は全体の高さ予算を 450px 以内に収める） -->
    <div class="stage-card">
      <canvas id="anim-canvas" width="640" height="240" class="stage-canvas"></canvas>

      <!-- 下部固定位置キャプション（最大2行、1行 13–16 全角文字目安） -->
      <div class="caption-box">
        <p id="caption-text" class="caption-text"></p>
      </div>
    </div>

    <!-- ここに Section 2 のシアターコントロールバーを配置 -->
  </div>

  <script>
    const canvas = document.getElementById('anim-canvas');
    const ctx = canvas.getContext('2d');

    /** ホスト変数優先 ＋ light/dark 自動判定で Canvas 描画色を解決（light-dark() 生文字列は渡さない） */
    function readThemeColors() {
      const root = document.documentElement;
      const s = getComputedStyle(root);
      const isDark =
        root.classList.contains('dark') ||
        (!root.classList.contains('light') && window.matchMedia('(prefers-color-scheme: dark)').matches);
      const get = (name, lightHex, darkHex) =>
        s.getPropertyValue(name).trim() || (isDark ? darkHex : lightHex);
      return {
        fg: get('--foreground', '#0f172a', '#f4f4f5'),
        muted: get('--muted-foreground', '#64748b', '#a1a1aa'),
        border: get('--border', '#cbd5e1', '#3f3f46'),
        primary: get('--primary', '#2563eb', '#3b82f6'),
        c1: get('--chart-1', '#2563eb', '#60a5fa'),
        c2: get('--chart-2', '#059669', '#34d399'),
      };
    }

    let lastRenderedFrame = null;
    function render(frame) {
      lastRenderedFrame = frame;
      const colors = readThemeColors();
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // ここに frame.motionT / frame.dimOpacity / colors を使った決定論的描画を記述
      document.getElementById('caption-text').textContent = frame.beat.caption;
    }

    // ライブテーマ切替時に再生位置・状態をリセットせず即時再描画（Antigravity themechange ＋ OS prefers-color-scheme 両対応）
    const rerenderOnThemeChange = () => {
      if (lastRenderedFrame) render(lastRenderedFrame);
    };
    window.addEventListener('themechange', rerenderOnThemeChange);
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', rerenderOnThemeChange);
  </script>
</body>
</html>
```
