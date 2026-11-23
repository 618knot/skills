# 【Layer 2】PR解説 2ペイン再生シアター 実装パターン集（ゼロ依存 HTML / SVG / CSS / JS）

本ドキュメントは、Layer 1 で確定したストーリーボード仕様を、外部CDNなし（Tailwind の許可スクリプトのみ可）の自己完結型 HTML/SVG 再生シアターとして実装するための再利用可能なパターン集である。

---

## 1. 決定論的タイムラインエンジン（無音 5フェーズ排他同期）

`explanatory-animation` の実証モデルをそのまま継承し、`setTimeout` を使わず単一時刻 `tMs` から全ビート・全フェーズを純粋計算する。

```javascript
/** 放送字幕規格に基づく Phase A（読解静止時間）算出（日本語 4.0 CPS / 英語 17.0 CPS） */
function calcReadingDwellMs(caption, lang = 'ja') {
  const cleanLen = caption.replace(/\s+/g, '').length;
  if (lang === 'en') {
    return Math.round(Math.max(833, Math.min(7000, (caption.trim().length / 17.0) * 1000)));
  }
  return Math.round(Math.max(1000, Math.min(7000, (cleanLen / 4.0) * 1000)));
}

const EASING = {
  outCubic: (t) => 1 - Math.pow(1 - t, 3),
  inOutCubic: (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
};
const clamp01 = (v) => Math.max(0, Math.min(1, v));

function buildPrTimeline(beats) {
  let cursor = 0;
  const compiled = beats.map((b, index) => {
    const phaseAMs = calcReadingDwellMs(b.caption, b.lang ?? 'ja');
    const phaseBMs = Math.max(200, Math.min(400, b.timing?.cueMs ?? 300));
    const phaseCMs = Math.max(500, Math.min(2000, b.timing?.motionMs ?? 1000));
    // Core の山場・Risk ビートは最低 1800ms、通常ビートは最低 1000ms の定着ホールド
    const minHold = (b.act === 'Risk' || b.isKeyBeat) ? 1800 : 1000;
    const phaseDMs = Math.max(minHold, b.timing?.holdMs ?? (b.act === 'Risk' ? 2000 : 1300));
    const phaseEMs = Math.max(40, b.timing?.boundaryMs ?? 60);
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

function evaluatePrTimeline(timeline, tMs, reducedMotion = false) {
  const clampedMs = Math.max(0, Math.min(timeline.totalMs, tMs));
  const beat = timeline.beats.find((b) => clampedMs < b.endMs) ?? timeline.beats[timeline.beats.length - 1];
  const localMs = clampedMs - beat.startMs;
  const { phaseAMs, phaseBMs, phaseCMs, phaseDMs } = beat.durations;

  const bStart = phaseAMs;
  const cStart = bStart + phaseBMs;
  const dStart = cStart + phaseCMs;
  const eStart = dStart + phaseDMs;

  let phase = 'A';
  let cueT = 0;
  let motionT = 0;

  if (localMs < bStart) {
    phase = 'A';
  } else if (localMs < cStart) {
    phase = 'B';
    cueT = EASING.outCubic(clamp01((localMs - bStart) / phaseBMs));
  } else if (localMs < dStart) {
    phase = 'C';
    cueT = 1;
    motionT = reducedMotion
      ? clamp01((localMs - cStart) / Math.min(200, phaseCMs))
      : EASING.inOutCubic(clamp01((localMs - cStart) / phaseCMs));
  } else if (localMs < eStart) {
    phase = 'D';
    cueT = 1;
    motionT = 1;
  } else {
    phase = 'E';
    cueT = 1;
    motionT = 1;
  }

  return {
    tMs: clampedMs,
    beatIndex: beat.index,
    beat,
    phase,
    cueT,
    motionT,
    // 非注目ノード/行のディミング透過率（1.0 → 0.20）
    dimOpacity: 1 - 0.8 * cueT,
  };
}
```

---

## 2. 2ペイン連動レンダリング（左：SVGフロー ＋ 右：抜粋コード＆行番号バッジ）

**ポイント**:
- `file:line` バッジはビート切替と同時に必ず同期更新する。
- 右ペインのコード行は最大 12行まで。`state: 'removed' | 'added' | 'risk' | 'focus' | 'context'` に応じて Phase C の `motionT` で滑らかに置換・強調し、変更がない文脈行はディミングする。
- 左ペインの SVG 要素と右ペインのコード行に同じ `data-key` を振り、ホバー時に双方向強調する。

```javascript
function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/**
 * 右ペインの抜粋コード描画（最大12行・Magic Move 風 Before→After 強調）
 */
function renderCodePane(codeSpec, motionT, cueT) {
  if (!codeSpec || !codeSpec.lines?.length) {
    return `<div class="text-xs text-[var(--muted-foreground)] p-3">このビートは全体構成マップに焦点を当てています。</div>`;
  }

  // 安全ガード：最大12行を超えないよう制限
  const lines = codeSpec.lines.slice(0, 12);

  const rowsHtml = lines.map((line) => {
    const keyAttr = line.dataKey ? `data-key="${line.dataKey}"` : '';
    let borderClass = 'border-transparent';
    let bgClass = '';
    let opacity = 1;
    let extraStyle = '';

    if (line.state === 'context') {
      opacity = 1 - 0.62 * cueT; // 非注目文脈行を 0.38 へ後退
    } else if (line.state === 'removed') {
      borderClass = 'border-rose-500';
      bgClass = 'bg-rose-500/10';
      // Phase C が進むにつれて薄い残像＋取り消し線へ退く（Trace保持）
      opacity = 1 - 0.65 * motionT;
      if (motionT > 0.5) extraStyle = 'text-decoration: line-through;';
    } else if (line.state === 'added') {
      borderClass = 'border-emerald-500';
      bgClass = 'bg-emerald-500/15';
      opacity = 0.25 + 0.75 * motionT;
    } else if (line.state === 'risk') {
      borderClass = 'border-amber-500';
      bgClass = 'bg-amber-500/15';
      opacity = 0.3 + 0.7 * motionT;
    } else if (line.state === 'focus') {
      borderClass = 'border-sky-500';
      bgClass = 'bg-sky-500/15';
    }

    return `
      <div ${keyAttr} class="flex items-start gap-2 px-2 py-0.5 border-l-2 ${borderClass} ${bgClass} font-mono text-xs leading-5 transition-opacity" style="opacity:${opacity.toFixed(2)};${extraStyle}">
        <span class="select-none text-[var(--muted-foreground)] w-7 text-right shrink-0">${line.num}</span>
        <code class="whitespace-pre overflow-x-auto">${escapeHtml(line.text)}</code>
      </div>
    `;
  }).join('');

  return `
    <div class="flex items-center justify-between px-2.5 py-1.5 border-b border-[var(--border)] bg-[var(--secondary)]/50 text-xs">
      <span class="font-mono font-semibold truncate">${escapeHtml(codeSpec.file)}</span>
      <span class="font-mono px-1.5 py-0.5 rounded bg-[var(--card)] border border-[var(--border)] shrink-0">${escapeHtml(codeSpec.lineRange)}</span>
    </div>
    <div class="py-1.5 overflow-x-auto">${rowsHtml}</div>
  `;
}
```

---

## 3. SVG Progressive Path ＆ Before 残像（Trace/History）パターン

変更前の経路を `stroke-dasharray="5 5"`・`opacity="0.22"` の残像として残したまま、変更後の経路を `stroke-dashoffset` で `motionT`（`0 → 1`）に同期して描く。

```javascript
/** SVG パスの全長を motionT (0..1) に応じて滑らかに伸長させる */
function applyProgressivePath(pathEl, motionT) {
  const len = pathEl.getTotalLength();
  pathEl.style.strokeDasharray = `${len}`;
  pathEl.style.strokeDashoffset = `${len * (1 - clamp01(motionT))}`;
}
```

```html
<!-- 左ペイン SVG 内の Before 残像 + After 経路の重ね合わせ例 -->
<g data-key="invalidate">
  <!-- Before 残像（消さずに比較基準として残す） -->
  <path d="M 120 90 C 190 90, 210 150, 290 150"
        fill="none" stroke="#ef4444" stroke-width="2"
        stroke-dasharray="5 5" opacity="0.24" />
  <!-- After 経路（Phase C で Progressive Path 描画） -->
  <path id="edge-after-invalidate"
        d="M 120 90 C 190 90, 210 45, 290 45"
        fill="none" stroke="#10b981" stroke-width="3"
        stroke-linecap="round" />
</g>
```

---

## 4. 双方向ホバーハイライト（`data-key` 連動）＆ キーボード・シアター制御

```javascript
// 左ペインSVGと右ペインコードの双方向ホバーハイライト
document.addEventListener('pointerover', (e) => {
  const el = e.target.closest('[data-key]');
  if (!el) return;
  const key = el.getAttribute('data-key');
  document.body.classList.add('is-highlighting');
  document.querySelectorAll(`[data-key="${key}"]`).forEach((n) => n.classList.add('is-active-key'));
});
document.addEventListener('pointerout', (e) => {
  const el = e.target.closest('[data-key]');
  if (!el) return;
  document.body.classList.remove('is-highlighting');
  document.querySelectorAll('.is-active-key').forEach((n) => n.classList.remove('is-active-key'));
});

// キーボードショートカット（Space: 再生/一時停止, ←/→: 1ビート戻し/送り, R: 現在ビート再再生）
window.addEventListener('keydown', (e) => {
  if (e.target.matches('input, button, select, textarea')) return;
  if (e.code === 'Space') { e.preventDefault(); togglePlay(); }
  if (e.code === 'ArrowLeft') { e.preventDefault(); jumpToBeat(Math.max(0, currentBeatIndex - 1)); }
  if (e.code === 'ArrowRight') { e.preventDefault(); jumpToBeat(Math.min(beats.length - 1, currentBeatIndex + 1)); }
  if (e.key === 'r' || e.key === 'R') { e.preventDefault(); jumpToBeat(currentBeatIndex); }
});
```

---

## 5. `generative_ui` 準拠スタンドアロン・ベース HTML テンプレート

- `:root` に独自色フォールバックを書かず、`var(--background)`, `var(--card)`, `var(--foreground)`, `var(--muted-foreground)`, `var(--border)`, `var(--primary)`, `var(--secondary)` を使用する。
- `prefers-reduced-motion: reduce` を初回自動検知しつつ、操作バー上の「動きを軽減」トグルボタンでも手動切替できるようにする。

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>PR Walkthrough Animation</title>
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
  <style>
    [data-key] { transition: opacity 0.15s ease, filter 0.15s ease; }
    body.is-highlighting [data-key]:not(.is-active-key) { opacity: 0.22 !important; }
    body.is-highlighting [data-key].is-active-key { filter: drop-shadow(0 0 5px currentColor); opacity: 1 !important; }
  </style>
</head>
<body class="bg-[var(--background)] text-[var(--foreground)] antialiased p-4">
  <div class="max-w-5xl mx-auto bg-[var(--card)] border border-[var(--border)] rounded-xl p-4 shadow-sm space-y-3">
    <!-- 1. ヘッダー + 5幕ナビゲーションタブ -->
    <!-- 2. 2ペイン本体 (grid-cols-1 lg:grid-cols-12: 左 col-span-7 SVGフロー / 右 col-span-5 抜粋コード) -->
    <!-- 3. 固定キャプション領域 (最大2行・高さ固定でレイアウトシフト防止) -->
    <!-- 4. シアター操作バー (Play/Pause, ◀戻す, 再再生, 進む▶, シークバー, 速度0.5x-2x, 手動ステップ, 動きを軽減) -->
  </div>
</body>
</html>
```
