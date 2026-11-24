# 【Layer 2-A 専用】PR解説 2ペイン再生シアター 実装パターン集（ゼロ依存 HTML / SVG / CSS / JS）

本ドキュメントは、Layer 1 で確定した 4ブロック中間ストーリーボード JSON のうち `semantic_core` ＋ `visual_directive` ＋ `adapter_silent_theater` を消費し、外部CDN一切なし（標準 Vanilla CSS のみ）の自己完結型 HTML/SVG 再生シアター（Mode A）として実装するための再利用可能なパターン集である。

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
    const adapter = b.adapter_silent_theater ?? {};
    const phase = b.semantic_core?.phase ?? b.act ?? 'code_focus';
    const caption = adapter.caption ?? b.caption ?? '';
    const phaseAMs = calcReadingDwellMs(caption, b.lang ?? 'ja');
    const phaseBMs = Math.max(200, Math.min(400, adapter.cue_ms ?? b.timing?.cueMs ?? 300));
    const phaseCMs = Math.max(500, Math.min(2000, adapter.motion_ms ?? b.timing?.motionMs ?? 1000));
    // 6フェーズ対応: Risk・重要ビートは >= 1800ms、最終 Summary は 1500–2000ms、通常ビートは >= 1000ms の定着ホールド
    const isRiskOrKey = phase === 'risk_audit' || phase === 'Risk' || b.isKeyBeat;
    const isSummary = phase === 'summary' || phase === 'Summary';
    const minHold = isRiskOrKey ? 1800 : isSummary ? 1500 : 1000;
    const defaultHold = isRiskOrKey ? 2000 : isSummary ? 1800 : 1300;
    const phaseDMs = Math.max(minHold, adapter.hold_ms ?? b.timing?.holdMs ?? defaultHold);
    const phaseEMs = Math.max(40, adapter.boundary_ms ?? b.timing?.boundaryMs ?? 60);
    const totalMs = phaseAMs + phaseBMs + phaseCMs + phaseDMs + phaseEMs;

    const entry = {
      ...b,
      caption,
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
    return `<div class="code-empty">このビートは全体構成マップに焦点を当てています。</div>`;
  }

  // 安全ガード：最大12行を超えないよう制限
  const lines = codeSpec.lines.slice(0, 12);

  const rowsHtml = lines.map((line) => {
    const keyVal = line.data_key ?? line.dataKey;
    const keyAttr = keyVal ? `data-key="${keyVal}"` : '';
    let modClass = 'code-line--context';
    let opacity = 1;
    let extraStyle = '';

    if (line.state === 'context') {
      opacity = 1 - 0.62 * cueT; // 非注目文脈行を 0.38 へ後退
    } else if (line.state === 'removed') {
      modClass = 'code-line--removed';
      // Phase C が進むにつれて薄い残像＋取り消し線へ退く（Trace保持）
      opacity = 1 - 0.65 * motionT;
      if (motionT > 0.5) extraStyle = 'text-decoration: line-through;';
    } else if (line.state === 'added') {
      modClass = 'code-line--added';
      opacity = 0.25 + 0.75 * motionT;
    } else if (line.state === 'risk') {
      modClass = 'code-line--risk';
      opacity = 0.3 + 0.7 * motionT;
    } else if (line.state === 'focus') {
      modClass = 'code-line--focus';
    }

    return `
      <div ${keyAttr} class="code-line ${modClass}" style="opacity:${opacity.toFixed(2)};${extraStyle}">
        <span class="code-num">${line.num}</span>
        <code class="code-text">${escapeHtml(line.text)}</code>
      </div>
    `;
  }).join('');

  const lineRange = codeSpec.line_range ?? codeSpec.lineRange ?? '';
  return `
    <div class="code-header">
      <span class="code-file">${escapeHtml(codeSpec.file)}</span>
      <span class="code-range">${escapeHtml(lineRange)}</span>
    </div>
    <div class="code-body">${rowsHtml}</div>
  `;
}

/**
 * Baum Principle 5 対応: 関連する2変更点（呼び出し元と呼び出し先、類似箇所2ファイル等）を同一画面に左右同時表示する
 */
function renderSplitCodePanes(codeStates, motionT, cueT) {
  if (!Array.isArray(codeStates) || codeStates.length < 2) {
    return `<div class="code-pane">${renderCodePane(codeStates?.[0], motionT, cueT)}</div>`;
  }
  return `
    <div class="code-split-grid">
      <div class="code-pane">${renderCodePane(codeStates[0], motionT, cueT)}</div>
      <div class="code-pane">${renderCodePane(codeStates[1], motionT, cueT)}</div>
    </div>
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

## 5. マルチ環境対応 Vanilla CSS スタンドアロン・ベース HTML テンプレート

- Claude Artifacts・Claude Code（ローカルHTML）・一般ブラウザ・Antigravity の全環境で外部CDNなしに動作するよう、`--ui-*` エイリアス変数でホスト注入変数（`--background`, `--card`, `--foreground`, `--muted-foreground`, `--border`, `--primary`, `--secondary`）を優先継承しつつ、未定義環境では `color-scheme: light dark` + `light-dark(...)` で自動適応する（ホスト変数を上書きしないよう `--background` / `--card` 等自体は `:root` に再定義しない）。
- `prefers-reduced-motion: reduce` を初回自動検知しつつ、操作バー上の「動きを軽減」トグルボタンでも手動切替できるようにする。

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>PR Walkthrough Animation</title>
  <style>
    :root {
      color-scheme: light dark;
      --ui-bg: var(--background, light-dark(#f8fafc, #09090b));
      --ui-surface: var(--card, light-dark(#ffffff, #18181b));
      --ui-surface-2: var(--secondary, light-dark(#f1f5f9, #27272a));
      --ui-fg: var(--foreground, light-dark(#0f172a, #f4f4f5));
      --ui-muted: var(--muted-foreground, light-dark(#64748b, #a1a1aa));
      --ui-border: var(--border, light-dark(#cbd5e1, #3f3f46));
      --ui-primary: var(--primary, light-dark(#2563eb, #3b82f6));
      --ui-primary-fg: var(--primary-foreground, #ffffff);
      --ui-added-accent: light-dark(#10b981, #34d399);
      --ui-added-bg: light-dark(rgba(16, 185, 129, 0.14), rgba(16, 185, 129, 0.16));
      --ui-removed-accent: light-dark(#e11d48, #fb7185);
      --ui-removed-bg: light-dark(rgba(244, 63, 94, 0.10), rgba(244, 63, 94, 0.14));
      --ui-risk-accent: light-dark(#d97706, #fbbf24);
      --ui-risk-bg: light-dark(rgba(245, 158, 11, 0.14), rgba(245, 158, 11, 0.16));
      --ui-focus-accent: light-dark(#0284c7, #38bdf8);
      --ui-focus-bg: light-dark(rgba(14, 165, 233, 0.12), rgba(56, 189, 248, 0.16));
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

    .pr-shell {
      max-width: 64rem;
      margin: 0 auto;
      background: var(--ui-surface);
      border: 1px solid var(--ui-border);
      border-radius: 12px;
      padding: 16px;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .pr-main-grid { display: grid; grid-template-columns: minmax(0, 1fr); gap: 12px; }
    @media (min-width: 900px) {
      .pr-main-grid { grid-template-columns: minmax(0, 7fr) minmax(0, 5fr); }
    }

    .code-split-grid { display: grid; grid-template-columns: minmax(0, 1fr); gap: 8px; }
    @media (min-width: 768px) {
      .code-split-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }

    .code-pane { border: 1px solid var(--ui-border); border-radius: 8px; overflow: hidden; background: var(--ui-surface); }
    .code-empty { font-size: 0.75rem; color: var(--ui-muted); padding: 12px; }
    .code-header {
      display: flex; align-items: center; justify-content: space-between; gap: 8px;
      padding: 6px 10px; border-bottom: 1px solid var(--ui-border);
      background: color-mix(in srgb, var(--ui-surface-2) 55%, transparent);
      font-size: 0.75rem;
    }
    .code-file { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .code-range {
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      padding: 2px 6px; border-radius: 4px; background: var(--ui-surface);
      border: 1px solid var(--ui-border); flex-shrink: 0;
    }
    .code-body { padding: 6px 0; overflow-x: auto; }
    .code-line {
      display: flex; align-items: flex-start; gap: 8px; padding: 2px 8px;
      border-left: 2px solid transparent;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.75rem; line-height: 1.25rem;
      transition: opacity 0.15s ease;
    }
    .code-line--removed { border-left-color: var(--ui-removed-accent); background: var(--ui-removed-bg); }
    .code-line--added { border-left-color: var(--ui-added-accent); background: var(--ui-added-bg); }
    .code-line--risk { border-left-color: var(--ui-risk-accent); background: var(--ui-risk-bg); }
    .code-line--focus { border-left-color: var(--ui-focus-accent); background: var(--ui-focus-bg); }
    .code-num { user-select: none; color: var(--ui-muted); width: 1.75rem; text-align: right; flex-shrink: 0; }
    .code-text { white-space: pre; overflow-x: auto; }

    [data-key] { transition: opacity 0.15s ease, filter 0.15s ease; }
    body.is-highlighting [data-key]:not(.is-active-key) { opacity: 0.22 !important; }
    body.is-highlighting [data-key].is-active-key { filter: drop-shadow(0 0 5px currentColor); opacity: 1 !important; }
  </style>
</head>
<body>
  <div class="pr-shell">
    <!-- 1. ヘッダー + 5幕ナビゲーションタブ -->
    <!-- 2. 2ペイン本体 (.pr-main-grid: 左 SVGフロー / 右 抜粋コード) -->
    <!-- 3. 固定キャプション領域 (最大2行・高さ固定でレイアウトシフト防止) -->
    <!-- 4. シアター操作バー (Play/Pause, ◀戻す, 再再生, 進む▶, シークバー, 速度0.5x-2x, 手動ステップ, 動きを軽減) -->
  </div>
</body>
</html>
```
