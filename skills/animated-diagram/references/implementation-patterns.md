# 動く挿絵（Animated Inline Diagram）実装パターン集

本ドキュメントは、Tailwind CDN を含む外部 `<script>` / `<link>` を一切使わない完全ゼロ依存の **標準 `<style>`（Vanilla CSS）＋インライン SVG/JS** により、Claude Desktop / claude.ai の Artifacts（CSP制限下）・Claude Code・技術記事埋め込み・Antigravity・単体ブラウザの全環境でそのまま動作する再利用テンプレートを提供する。

---

## 1. スリム `<figure>` 骨格＆ `:root` 非汚染セマンティック CSS ベース

- **重要規約**:
  - `:root` に色変数を定義しない（ホスト注入トークンの干渉防止）。フォールバックが必要な場合は各要素ルール内で `var(--token, light-dark(lightVal, darkVal))` を直接書く。
  - ボタンとピルはネイティブ `<button type="button">`、`min-block-size: 24px; min-inline-size: 24px`、非選択／選択双方で文字コントラスト比 `>= 4.5:1`（フォールバック `#1d4ed8` 上 `#ffffff` は `6.7:1`）。
  - `user-select: none` は操作ボタンのみに限定し、`<svg>` 内の技術用語や `<figcaption>` は選択・コピー可能にする。

```html
<style>
  html { color-scheme: light dark; }
  html.light { color-scheme: light; }
  html.dark { color-scheme: dark; }

  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 12px;
    background: var(--background, light-dark(#f8fafc, #09090b));
    color: var(--foreground, light-dark(#0f172a, #f4f4f5));
    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    font-size: 14px;
    -webkit-font-smoothing: antialiased;
  }
  /* チャット内インライン埋め込み（<agent-embed> 等）や記事への透過埋め込み時は body.is-inline を付与 */
  body.is-inline { background: transparent; padding: 0; }

  .ad-figure {
    margin: 0 auto;
    max-width: 720px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    border: 1px solid var(--card-border, var(--border, light-dark(#cbd5e1, #3f3f46)));
    border-radius: 10px;
    background: var(--card, light-dark(#ffffff, #18181b));
    padding: 10px 12px;
  }
  /* インライン埋め込み内で外側枠線を二重にしたくない場合は .ad-figure--flush を併用 */
  body.is-inline .ad-figure--flush {
    border: none;
    border-radius: 0;
    background: transparent;
    padding: 4px 0;
  }

  .ad-header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding-bottom: 6px;
    border-bottom: 1px solid var(--card-border, var(--border, light-dark(#e2e8f0, #27272a)));
  }
  .ad-title {
    margin: 0;
    font-size: 13px;
    font-weight: 600;
    color: var(--foreground, light-dark(#0f172a, #f4f4f5));
  }
  .ad-controls {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 6px;
  }
  .ad-btn {
    min-block-size: 24px;
    min-inline-size: 24px;
    padding: 3px 10px;
    border-radius: 9999px;
    border: 1px solid var(--border, light-dark(#94a3b8, #52525b));
    background: var(--secondary, light-dark(#f1f5f9, #27272a));
    color: var(--secondary-foreground, var(--foreground, light-dark(#0f172a, #f4f4f5)));
    font-size: 12px;
    font-weight: 500;
    line-height: 1.25;
    cursor: pointer;
    user-select: none;
    transition: background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease;
  }
  .ad-btn:hover {
    border-color: var(--primary, light-dark(#1d4ed8, #60a5fa));
  }
  .ad-btn[aria-pressed="true"] {
    background: var(--primary, light-dark(#1d4ed8, #2563eb));
    color: var(--primary-foreground, #ffffff);
    border-color: transparent;
    font-weight: 600;
  }
  .ad-btn:focus-visible {
    outline: 2px solid var(--primary, light-dark(#1d4ed8, #60a5fa));
    outline-offset: 2px;
  }

  .ad-stage {
    width: 100%;
    height: auto;
    display: block;
    overflow: visible;
  }
  .ad-caption {
    margin: 0;
    padding-top: 6px;
    border-top: 1px solid var(--card-border, var(--border, light-dark(#e2e8f0, #27272a)));
    font-size: 12px;
    line-height: 1.45;
    color: var(--muted-foreground, light-dark(#475569, #a1a1aa));
  }

  /* ホバー / フォーカス経路ハイライトと静止フォールバック用の状態クラス */
  .ad-edge-rail {
    fill: none;
    stroke: var(--border, light-dark(#cbd5e1, #3f3f46));
    stroke-width: 2;
  }
  .ad-edge-active {
    fill: none;
    stroke-width: 3;
    stroke-linecap: round;
    transition: opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1);
  }
  .ad-node-box {
    fill: var(--card, light-dark(#ffffff, #18181b));
    stroke: var(--border, light-dark(#94a3b8, #52525b));
    stroke-width: 1.5;
    transition: stroke 0.3s cubic-bezier(0.4, 0, 0.2, 1), stroke-width 0.3s ease;
  }
  .ad-node.is-active .ad-node-box {
    stroke: var(--primary, light-dark(#1d4ed8, #60a5fa));
    stroke-width: 2.5;
  }
  .ad-stage.is-hovering [data-route]:not(.is-highlighted) {
    opacity: 0.25;
  }
  .ad-stage.is-static .ad-token {
    display: none;
  }
</style>
```

---

## 2. Single-Wave + Rest Dwell 決定論的ループエンジン

**目的**: `setTimeout` 連鎖や常時ループ CSS を排し、任意の時刻 `elapsedMs` から「各ホップの進捗 `progress ∈ [0, 1]`」「通過完了エッジ履歴」「アクティブノード集合」「Rest Dwell 中かどうか」を純粋計算する。`IntersectionObserver` と `visibilitychange` により、記事上で画面外へスクロールされた挿絵は自動停止して負荷を抑える。

```javascript
const clamp01 = (v) => Math.max(0, Math.min(1, v));
const easeInOutCubic = (t) =>
  t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

/**
 * シナリオ定義から1周期の総時間（アクティブ波 + Rest Dwell 1200-1800ms）を算出
 * scenario: { id, caption, restDwellMs, hops: [{ id, edgeId, from, to, startMs, durationMs, tone, label }] }
 */
function compileScenario(scenario) {
  const waveEndMs = scenario.hops.reduce(
    (max, h) => Math.max(max, h.startMs + h.durationMs),
    0
  );
  // 休止時間は必ず 1200ms〜1800ms に収める
  const restDwellMs = Math.max(1200, Math.min(1800, scenario.restDwellMs ?? 1500));
  return { ...scenario, waveEndMs, restDwellMs, cycleMs: waveEndMs + restDwellMs };
}

/**
 * 任意の時刻 elapsedMs に対する単一波状態を純粋計算
 */
function evaluateWave(compiledScenario, elapsedMs) {
  const t = ((elapsedMs % compiledScenario.cycleMs) + compiledScenario.cycleMs) % compiledScenario.cycleMs;
  const inRestDwell = t >= compiledScenario.waveEndMs;
  const activeEdges = new Map();
  const completedEdges = new Set();
  const activeNodes = new Set();
  const movingTokens = [];

  compiledScenario.hops.forEach((hop) => {
    const endMs = hop.startMs + hop.durationMs;
    if (t >= endMs) {
      completedEdges.add(hop.edgeId);
      activeEdges.set(hop.edgeId, 1);
      // 休止直前（波の最終ノード）や直近完了ノードを控えめに保持
      if (inRestDwell && endMs === compiledScenario.waveEndMs) {
        activeNodes.add(hop.to);
      }
    } else if (t >= hop.startMs) {
      const raw = clamp01((t - hop.startMs) / hop.durationMs);
      const eased = easeInOutCubic(raw);
      activeEdges.set(hop.edgeId, eased);
      activeNodes.add(hop.from);
      if (raw > 0.72) activeNodes.add(hop.to);
      movingTokens.push({ hop, progress: eased });
    }
  });

  // 同時独立移動トークンの上限（MOT <= 4）を安全ガード
  return {
    t,
    inRestDwell,
    activeEdges,
    completedEdges,
    activeNodes,
    movingTokens: movingTokens.slice(0, 4),
  };
}

/**
 * 省電力・決定論的アニメーションループ（IntersectionObserver + visibilitychange 連携）
 */
function createDiagramRunner(containerEl, onTick) {
  let rafId = null;
  let lastNow = null;
  let elapsedMs = 0;
  let isVisible = true;
  let isPaused = false;
  let reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const stopLoop = () => {
    if (rafId !== null) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
    lastNow = null;
  };

  const frame = (now) => {
    if (isPaused || reducedMotion || !isVisible || document.hidden) {
      stopLoop();
      return;
    }
    if (lastNow !== null) {
      // タブ復帰時の巨大 dt によるワープを 100ms 上限で防止
      const dt = Math.min(100, Math.max(0, now - lastNow));
      elapsedMs += dt;
    }
    lastNow = now;
    onTick(elapsedMs, false);
    rafId = requestAnimationFrame(frame);
  };

  const sync = () => {
    if (isPaused || reducedMotion) {
      stopLoop();
      onTick(elapsedMs, true); // 第2引数 isStatic = true で静的矢印表示へ
      return;
    }
    if (isVisible && !document.hidden && rafId === null) {
      lastNow = null;
      rafId = requestAnimationFrame(frame);
    } else if (!isVisible || document.hidden) {
      stopLoop();
    }
  };

  const observer = new IntersectionObserver(
    (entries) => {
      isVisible = entries.some((e) => e.isIntersecting);
      sync();
    },
    { threshold: 0.1 }
  );
  observer.observe(containerEl);
  document.addEventListener('visibilitychange', sync);

  return {
    setPaused(next) { isPaused = next; sync(); },
    setReducedMotion(next) { reducedMotion = next; sync(); },
    resetWave() { elapsedMs = 0; onTick(0, isPaused || reducedMotion); },
    isStatic() { return isPaused || reducedMotion; },
    destroy() { stopLoop(); observer.disconnect(); document.removeEventListener('visibilitychange', sync); },
  };
}
```

---

## 3. SVG Progressive Path 発光＋曲線追従トークン描画ヘルパー

**目的**: 初期化時に `path.getTotalLength()` を1回だけキャッシュして毎フレームのレイアウト再計算を防ぎ、エルボー曲線やベジェ弧に沿って Progressive Path と信号パケットを正確に移動させる。

```javascript
/**
 * 対象 SVG 内の発光オーバーレイパス長をキャッシュして描画ヘルパーを返す
 */
function createSvgRenderer(svgEl) {
  const pathCache = new Map();
  svgEl.querySelectorAll('[data-edge]').forEach((pathEl) => {
    const id = pathEl.getAttribute('data-edge');
    const length = pathEl.getTotalLength();
    pathEl.style.strokeDasharray = `${length}`;
    pathEl.style.strokeDashoffset = `${length}`;
    pathCache.set(id, { el: pathEl, length });
  });

  const nodeMap = new Map();
  svgEl.querySelectorAll('[data-node]').forEach((el) => {
    nodeMap.set(el.getAttribute('data-node'), el);
  });

  /**
   * waveState と scenario に基づき全エッジ・ノード・トークンを更新
   * isStatic === true（停止または prefers-reduced-motion）のときは全有効エッジを完成状態で静止描画
   */
  return function renderDiagramFrame(scenario, waveState, isStatic, tokenEls) {
    svgEl.classList.toggle('is-static', isStatic);

    const scenarioEdgeIds = new Set(scenario.hops.map((h) => h.edgeId));

    pathCache.forEach(({ el, length }, edgeId) => {
      const enabled = scenarioEdgeIds.has(edgeId);
      el.style.opacity = enabled ? '1' : '0.16';
      if (!enabled) {
        el.style.strokeDashoffset = `${length}`;
        return;
      }
      const progress = isStatic ? 1 : (waveState.activeEdges.get(edgeId) ?? 0);
      el.style.strokeDashoffset = `${(length * (1 - progress)).toFixed(2)}`;
    });

    nodeMap.forEach((el, nodeId) => {
      const active = !isStatic && waveState.activeNodes.has(nodeId);
      el.classList.toggle('is-active', active);
    });

    // トークン要素の配置更新（静止時は .is-static により CSS で非表示）
    tokenEls.forEach((tokenEl, idx) => {
      const item = !isStatic ? waveState.movingTokens[idx] : null;
      if (!item) {
        tokenEl.setAttribute('visibility', 'hidden');
        return;
      }
      const entry = pathCache.get(item.hop.edgeId);
      if (!entry) return;
      const pt = entry.el.getPointAtLength(entry.length * item.progress);
      tokenEl.setAttribute('visibility', 'visible');
      tokenEl.setAttribute('transform', `translate(${pt.x.toFixed(1)}, ${pt.y.toFixed(1)})`);
      const labelEl = tokenEl.querySelector('text');
      if (labelEl && item.hop.label) labelEl.textContent = item.hop.label;
    });
  };
}
```

---

## 4. Micro-Toggle（シナリオ切替ピル＋停止ボタン）＆ `prefers-reduced-motion` 制御

**目的**: WCAG 2.2 SC 2.2.2 / 2.3.3 に準拠し、`prefers-reduced-motion: reduce` 変更時およびユーザー操作時に、雑な CSS リセットではなく「意味のある静的矢印＋番号表示」へ即座に切り替える。

```javascript
function attachMicroToggles({
  scenarios,
  scenarioButtons,
  pauseButton,
  captionEl,
  runner,
  onScenarioChange,
}) {
  let currentId = scenarios[0].id;
  let userPaused = false;
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)');

  const updatePauseUi = () => {
    const pausedByMotion = mq.matches;
    const effectivelyPaused = userPaused || pausedByMotion;
    pauseButton.setAttribute('aria-pressed', String(effectivelyPaused));
    pauseButton.textContent = effectivelyPaused ? '▶ 再開' : '⏸ 停止';
  };

  scenarioButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetId = btn.dataset.scenario;
      if (!targetId || targetId === currentId) return;
      currentId = targetId;
      scenarioButtons.forEach((b) =>
        b.setAttribute('aria-pressed', String(b.dataset.scenario === currentId))
      );
      const nextScenario = scenarios.find((s) => s.id === currentId);
      if (captionEl && nextScenario) captionEl.textContent = nextScenario.caption;
      onScenarioChange(nextScenario);
      runner.resetWave();
    });
  });

  pauseButton.addEventListener('click', () => {
    userPaused = !userPaused;
    // 明示的に再開を押した場合は、一時的にアプリ側再生を許可するなら userPaused 優先設計にも切替可
    runner.setPaused(userPaused);
    updatePauseUi();
  });

  mq.addEventListener('change', () => {
    runner.setReducedMotion(mq.matches);
    updatePauseUi();
  });

  updatePauseUi();
}
```

---

## 5. ホバー／フォーカス経路ハイライト ＋ `<canvas>` ライブテーマ同期

```javascript
/**
 * ノードまたはエッジへのホバー／キーボードフォーカスで関連経路を強調（非関連は opacity: 0.25）
 * ※ 初期状態でラベルを隠さず、あくまで読解補助としてのみ動作させる
 */
function attachRouteHighlight(svgEl) {
  const activate = (route) => {
    svgEl.classList.add('is-hovering');
    svgEl.querySelectorAll(`[data-route~="${route}"]`).forEach((el) => el.classList.add('is-highlighted'));
  };
  const clear = () => {
    svgEl.classList.remove('is-hovering');
    svgEl.querySelectorAll('.is-highlighted').forEach((el) => el.classList.remove('is-highlighted'));
  };

  svgEl.addEventListener('pointerover', (e) => {
    const target = e.target.closest('[data-route]');
    if (target) activate(target.getAttribute('data-route').split(' ')[0]);
  });
  svgEl.addEventListener('pointerout', (e) => {
    if (!e.relatedTarget || !svgEl.contains(e.relatedTarget) || !e.relatedTarget.closest('[data-route]')) {
      clear();
    }
  });
  svgEl.addEventListener('focusin', (e) => {
    const target = e.target.closest('[data-route]');
    if (target) activate(target.getAttribute('data-route').split(' ')[0]);
  });
  svgEl.addEventListener('focusout', clear);
}

/**
 * 例外的に <canvas> を併用する場合のライブテーマ再描画ヘルパー
 */
function watchThemeForCanvas(drawFn) {
  const resolveColors = () => {
    const root = document.documentElement;
    const s = getComputedStyle(root);
    const isDark =
      root.classList.contains('dark') ||
      (!root.classList.contains('light') && window.matchMedia('(prefers-color-scheme: dark)').matches);
    const pick = (token, lightHex, darkHex) => s.getPropertyValue(token).trim() || (isDark ? darkHex : lightHex);
    return {
      fg: pick('--foreground', '#0f172a', '#f4f4f5'),
      border: pick('--border', '#cbd5e1', '#3f3f46'),
      primary: pick('--primary', '#1d4ed8', '#60a5fa'),
      c2: pick('--chart-2', '#059669', '#34d399'),
    };
  };
  const redraw = () => drawFn(resolveColors());
  window.addEventListener('themechange', redraw);
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', redraw);
  redraw();
}
```

---

## 6. 完全動作リファレンス実装（Request-Response `Cache Hit / Cache Miss` 挿絵）＋ 他4パターン SVG 要所

### 6.1 完全動作する自己完結 HTML 挿絵（高さ約 `310px`）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <style>
    html { color-scheme: light dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 8px;
      background: var(--background, light-dark(#f8fafc, #09090b));
      color: var(--foreground, light-dark(#0f172a, #f4f4f5));
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      font-size: 14px;
    }
    body.is-inline { background: transparent; padding: 0; }
    .ad-figure {
      margin: 0 auto;
      max-width: 720px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      border: 1px solid var(--card-border, var(--border, light-dark(#cbd5e1, #3f3f46)));
      border-radius: 10px;
      background: var(--card, light-dark(#ffffff, #18181b));
      padding: 10px 12px;
    }
    .ad-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding-bottom: 6px;
      border-bottom: 1px solid var(--card-border, var(--border, light-dark(#e2e8f0, #27272a)));
    }
    .ad-title { margin: 0; font-size: 13px; font-weight: 600; }
    .ad-controls { display: flex; flex-wrap: wrap; gap: 6px; }
    .ad-btn {
      min-block-size: 24px;
      min-inline-size: 24px;
      padding: 3px 10px;
      border-radius: 9999px;
      border: 1px solid var(--border, light-dark(#94a3b8, #52525b));
      background: var(--secondary, light-dark(#f1f5f9, #27272a));
      color: var(--secondary-foreground, var(--foreground, light-dark(#0f172a, #f4f4f5)));
      font-size: 12px;
      font-weight: 500;
      cursor: pointer;
      user-select: none;
    }
    .ad-btn[aria-pressed="true"] {
      background: var(--primary, light-dark(#1d4ed8, #2563eb));
      color: var(--primary-foreground, #ffffff);
      border-color: transparent;
      font-weight: 600;
    }
    .ad-btn:focus-visible {
      outline: 2px solid var(--primary, light-dark(#1d4ed8, #60a5fa));
      outline-offset: 2px;
    }
    .ad-stage { width: 100%; height: auto; display: block; }
    .ad-caption {
      margin: 0;
      padding-top: 6px;
      border-top: 1px solid var(--card-border, var(--border, light-dark(#e2e8f0, #27272a)));
      font-size: 12px;
      line-height: 1.45;
      color: var(--muted-foreground, light-dark(#475569, #a1a1aa));
    }
    .ad-rail { fill: none; stroke: var(--border, light-dark(#cbd5e1, #3f3f46)); stroke-width: 2; }
    .ad-rail--dashed { stroke-dasharray: 4 4; }
    .ad-active { fill: none; stroke-width: 3; stroke-linecap: round; }
    .ad-node-box {
      fill: var(--card, light-dark(#ffffff, #18181b));
      stroke: var(--border, light-dark(#94a3b8, #52525b));
      stroke-width: 1.5;
      transition: stroke 0.3s cubic-bezier(0.4, 0, 0.2, 1), stroke-width 0.3s ease;
    }
    .ad-node.is-active .ad-node-box {
      stroke: var(--primary, light-dark(#1d4ed8, #60a5fa));
      stroke-width: 2.5;
    }
    .ad-stage.is-static .ad-token { display: none; }
  </style>
</head>
<body>
  <figure id="cache-diagram" class="ad-figure">
    <div class="ad-header">
      <p class="ad-title">Read-Through キャッシュの検索経路</p>
      <div class="ad-controls">
        <button type="button" class="ad-btn" data-scenario="hit" aria-pressed="true">Cache Hit</button>
        <button type="button" class="ad-btn" data-scenario="miss" aria-pressed="false">Cache Miss</button>
        <button type="button" id="btn-pause" class="ad-btn" aria-pressed="false">⏸ 停止</button>
      </div>
    </div>

    <svg id="stage" class="ad-stage" viewBox="0 0 680 206" role="img" aria-labelledby="fig-title fig-desc">
      <title id="fig-title">Read-Through キャッシュ構成とリクエスト往復</title>
      <desc id="fig-desc">ClientからAPI Gateway、Redis Cache、Cache Miss時のみPrimary DBへ到達し応答を返す経路図。</desc>
      <defs>
        <marker id="arrow-req" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto">
          <path d="M 1 2 L 8 5 L 1 8 z" fill="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" />
        </marker>
        <marker id="arrow-res" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto">
          <path d="M 1 2 L 8 5 L 1 8 z" fill="var(--chart-2, light-dark(#047857, #34d399))" />
        </marker>
      </defs>

      <!-- 固定配線レール（往路 y=76 と復路 y=98 を平行分離） -->
      <path class="ad-rail" d="M 136 76 L 210 76" marker-end="url(#arrow-req)" />
      <path class="ad-rail" d="M 332 76 L 406 76" marker-end="url(#arrow-req)" />
      <path class="ad-rail ad-rail--dashed" d="M 462 114 L 462 148" marker-end="url(#arrow-req)" />
      <path class="ad-rail ad-rail--dashed" d="M 442 148 L 442 114" marker-end="url(#arrow-res)" />
      <path class="ad-rail" d="M 406 98 L 332 98" marker-end="url(#arrow-res)" />
      <path class="ad-rail" d="M 210 98 L 136 98" marker-end="url(#arrow-res)" />

      <!-- 発光オーバーレイ（Progressive Path） -->
      <path class="ad-active" data-edge="c-api" d="M 136 76 L 210 76" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" marker-end="url(#arrow-req)" />
      <path class="ad-active" data-edge="api-redis" d="M 332 76 L 406 76" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" marker-end="url(#arrow-req)" />
      <path class="ad-active" data-edge="redis-db" d="M 462 114 L 462 148" stroke="var(--chart-3, light-dark(#b45309, #fbbf24))" />
      <path class="ad-active" data-edge="db-redis" d="M 442 148 L 442 114" stroke="var(--chart-2, light-dark(#047857, #34d399))" />
      <path class="ad-active" data-edge="redis-api" d="M 406 98 L 332 98" stroke="var(--chart-2, light-dark(#047857, #34d399))" marker-end="url(#arrow-res)" />
      <path class="ad-active" data-edge="api-c" d="M 210 98 L 136 98" stroke="var(--chart-2, light-dark(#047857, #34d399))" marker-end="url(#arrow-res)" />

      <!-- 固定番号・役割ラベル（静止画でも100%読解可能） -->
      <text x="173" y="64" text-anchor="middle" font-size="12" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">① GET</text>
      <text x="369" y="64" text-anchor="middle" font-size="12" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">② Lookup</text>
      <text x="480" y="135" text-anchor="start" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">③ Miss時Query</text>
      <text x="369" y="118" text-anchor="middle" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">値返却</text>
      <text x="173" y="118" text-anchor="middle" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">200 JSON</text>

      <!-- 固定ノード群 -->
      <g class="ad-node" data-node="client">
        <rect class="ad-node-box" x="24" y="56" width="112" height="58" rx="8" />
        <text x="80" y="81" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">Client</text>
        <text x="80" y="99" text-anchor="middle" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">Browser / App</text>
      </g>
      <g class="ad-node" data-node="api">
        <rect class="ad-node-box" x="210" y="56" width="122" height="58" rx="8" />
        <text x="271" y="81" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">API Server</text>
        <text x="271" y="99" text-anchor="middle" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">Read-Through</text>
      </g>
      <g class="ad-node" data-node="redis">
        <rect class="ad-node-box" x="406" y="56" width="124" height="58" rx="8" />
        <text x="468" y="81" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">Redis Cache</text>
        <text x="468" y="99" text-anchor="middle" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">In-Memory</text>
      </g>
      <g class="ad-node" data-node="db">
        <rect class="ad-node-box" x="406" y="148" width="124" height="46" rx="8" />
        <text x="468" y="176" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">Primary DB</text>
      </g>

      <!-- 単一移動信号トークン（サイズ最小限・Rest Dwell中は非表示） -->
      <g id="token-0" class="ad-token" visibility="hidden">
        <circle r="6" fill="var(--primary, light-dark(#1d4ed8, #60a5fa))" />
      </g>
    </svg>

    <figcaption id="fig-caption" class="ad-caption">
      Cache Hit：Redis 内にキーが存在するため DB へ到達せず即座に 200 JSON を返却します。
    </figcaption>
  </figure>

  <script>
    const SCENARIOS = [
      {
        id: 'hit',
        caption: 'Cache Hit：Redis 内にキーが存在するため DB へ到達せず即座に 200 JSON を返却します。',
        restDwellMs: 1500,
        hops: [
          { edgeId: 'c-api', from: 'client', to: 'api', startMs: 0, durationMs: 420 },
          { edgeId: 'api-redis', from: 'api', to: 'redis', startMs: 460, durationMs: 420 },
          { edgeId: 'redis-api', from: 'redis', to: 'api', startMs: 960, durationMs: 420 },
          { edgeId: 'api-c', from: 'api', to: 'client', startMs: 1420, durationMs: 420 },
        ],
      },
      {
        id: 'miss',
        caption: 'Cache Miss：Redis 不在時に Primary DB へフォールバックし、キャッシュ充填後に返却します。',
        restDwellMs: 1600,
        hops: [
          { edgeId: 'c-api', from: 'client', to: 'api', startMs: 0, durationMs: 400 },
          { edgeId: 'api-redis', from: 'api', to: 'redis', startMs: 430, durationMs: 400 },
          { edgeId: 'redis-db', from: 'redis', to: 'db', startMs: 860, durationMs: 440 },
          { edgeId: 'db-redis', from: 'db', to: 'redis', startMs: 1360, durationMs: 440 },
          { edgeId: 'redis-api', from: 'redis', to: 'api', startMs: 1840, durationMs: 400 },
          { edgeId: 'api-c', from: 'api', to: 'client', startMs: 2280, durationMs: 400 },
        ],
      },
    ];

    // Section 2〜4 の compileScenario / evaluateWave / createSvgRenderer / createDiagramRunner / attachMicroToggles を接続して起動
    const clamp01 = (v) => Math.max(0, Math.min(1, v));
    const easeInOutCubic = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
    const compileScenario = (s) => {
      const waveEndMs = s.hops.reduce((m, h) => Math.max(m, h.startMs + h.durationMs), 0);
      const restDwellMs = Math.max(1200, Math.min(1800, s.restDwellMs ?? 1500));
      return { ...s, waveEndMs, restDwellMs, cycleMs: waveEndMs + restDwellMs };
    };
    let activeScenario = compileScenario(SCENARIOS[0]);
    const svgEl = document.getElementById('stage');
    const pathCache = new Map();
    svgEl.querySelectorAll('[data-edge]').forEach((el) => {
      const len = el.getTotalLength();
      el.style.strokeDasharray = `${len}`;
      el.style.strokeDashoffset = `${len}`;
      pathCache.set(el.getAttribute('data-edge'), { el, len });
    });
    const tokenEl = document.getElementById('token-0');

    const renderAt = (elapsedMs, isStatic) => {
      svgEl.classList.toggle('is-static', isStatic);
      const t = elapsedMs % activeScenario.cycleMs;
      const enabled = new Set(activeScenario.hops.map((h) => h.edgeId));
      const activeNodes = new Set();
      let activeHop = null;
      let hopProgress = 0;

      pathCache.forEach(({ el, len }, id) => {
        el.style.opacity = enabled.has(id) ? '1' : '0.18';
        if (!enabled.has(id)) { el.style.strokeDashoffset = `${len}`; return; }
        if (isStatic) { el.style.strokeDashoffset = '0'; return; }
        const hop = activeScenario.hops.find((h) => h.edgeId === id);
        if (t >= hop.startMs + hop.durationMs) {
          el.style.strokeDashoffset = '0';
        } else if (t >= hop.startMs) {
          const p = easeInOutCubic(clamp01((t - hop.startMs) / hop.durationMs));
          el.style.strokeDashoffset = `${(len * (1 - p)).toFixed(2)}`;
          activeHop = hop;
          hopProgress = p;
          activeNodes.add(hop.from);
          if (p > 0.7) activeNodes.add(hop.to);
        } else {
          el.style.strokeDashoffset = `${len}`;
        }
      });

      svgEl.querySelectorAll('[data-node]').forEach((n) =>
        n.classList.toggle('is-active', !isStatic && activeNodes.has(n.getAttribute('data-node')))
      );
      if (isStatic || !activeHop) {
        tokenEl.setAttribute('visibility', 'hidden');
      } else {
        const pt = pathCache.get(activeHop.edgeId).el.getPointAtLength(
          pathCache.get(activeHop.edgeId).len * hopProgress
        );
        tokenEl.setAttribute('visibility', 'visible');
        tokenEl.setAttribute('transform', `translate(${pt.x.toFixed(1)}, ${pt.y.toFixed(1)})`);
      }
    };

    // 簡易ランナー接続
    let paused = false;
    let reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    let elapsed = 0;
    let last = null;
    let visible = true;
    const figEl = document.getElementById('cache-diagram');
    const step = (now) => {
      if (paused || reduced || !visible || document.hidden) { last = null; return; }
      if (last !== null) elapsed += Math.min(100, now - last);
      last = now;
      renderAt(elapsed, false);
      requestAnimationFrame(step);
    };
    const sync = () => {
      if (paused || reduced) { renderAt(elapsed, true); return; }
      if (visible && !document.hidden) { last = null; requestAnimationFrame(step); }
    };
    new IntersectionObserver((es) => { visible = es.some((e) => e.isIntersecting); sync(); }, { threshold: 0.1 }).observe(figEl);
    document.addEventListener('visibilitychange', sync);
    document.querySelectorAll('[data-scenario]').forEach((btn) => {
      btn.addEventListener('click', () => {
        activeScenario = compileScenario(SCENARIOS.find((s) => s.id === btn.dataset.scenario));
        document.querySelectorAll('[data-scenario]').forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
        document.getElementById('fig-caption').textContent = activeScenario.caption;
        elapsed = 0;
        renderAt(0, paused || reduced);
      });
    });
    const pauseBtn = document.getElementById('btn-pause');
    const updatePauseBtn = () => {
      const stop = paused || reduced;
      pauseBtn.setAttribute('aria-pressed', String(stop));
      pauseBtn.textContent = stop ? '▶ 再開' : '⏸ 停止';
    };
    pauseBtn.addEventListener('click', () => { paused = !paused; updatePauseBtn(); sync(); });
    window.matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', (e) => {
      reduced = e.matches; updatePauseBtn(); sync();
    });
    updatePauseBtn();
    sync();
  </script>
</body>
</html>
```

---

### 6.2 残り4パターンの SVG 骨格スニペット

#### (a) 非同期キュー・ワーカー並列（Queue 可視スロット + Fan-out）
```html
<!-- Queue 内部スロット（投入時に data-slot="0..2" を点灯、Fan-out 時に消灯） -->
<g class="ad-node" data-node="queue">
  <rect class="ad-node-box" x="200" y="64" width="120" height="72" rx="8" />
  <text x="260" y="84" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">Job Queue</text>
  <rect data-slot="0" x="216" y="96" width="24" height="24" rx="4" fill="var(--secondary, light-dark(#e2e8f0, #27272a))" />
  <rect data-slot="1" x="248" y="96" width="24" height="24" rx="4" fill="var(--secondary, light-dark(#e2e8f0, #27272a))" />
  <rect data-slot="2" x="280" y="96" width="24" height="24" rx="4" fill="var(--secondary, light-dark(#e2e8f0, #27272a))" />
</g>
<!-- 並列ワーカー 3分岐（MOT <= 4 を満たす） -->
<path class="ad-active" data-edge="q-w1" d="M 320 90 C 360 90, 370 46, 410 46" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" />
<path class="ad-active" data-edge="q-w2" d="M 320 100 L 410 100" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" />
<path class="ad-active" data-edge="q-w3" d="M 320 110 C 360 110, 370 154, 410 154" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" />
```

#### (b) シーケンス図・縦タイムライン（固定ライフライン + 薄いアクティベーション矩形）
```html
<!-- アクター列 x = 110, 340, 570、メッセージ段ピッチ 40px（y = 84, 124, 164, 204） -->
<line x1="110" y1="54" x2="110" y2="232" stroke="var(--border, light-dark(#cbd5e1, #3f3f46))" stroke-dasharray="4 4" />
<line x1="340" y1="54" x2="340" y2="232" stroke="var(--border, light-dark(#cbd5e1, #3f3f46))" stroke-dasharray="4 4" />
<line x1="570" y1="54" x2="570" y2="232" stroke="var(--border, light-dark(#cbd5e1, #3f3f46))" stroke-dasharray="4 4" />
<!-- 受信側アクティベーション区間 -->
<rect x="335" y="84" width="10" height="80" rx="2" fill="var(--secondary, light-dark(#e2e8f0, #27272a))" stroke="var(--border, light-dark(#94a3b8, #52525b))" />
<!-- 段1・段2のメッセージ矢印と固定番号ラベル -->
<path class="ad-active" data-edge="seq-1" d="M 110 84 L 335 84" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" marker-end="url(#arrow-req)" />
<text x="222" y="75" text-anchor="middle" font-size="12" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">① POST /token</text>
```

#### (c) ステートマシン・状態遷移図（上下分離カーブ + 自己ループ）
```html
<!-- 初期状態マーカー -->
<circle cx="32" cy="110" r="6" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))" />
<path class="ad-rail" d="M 38 110 L 76 110" marker-end="url(#arrow-req)" />
<!-- Closed <-> Open の双方向カーブ（上弧 Q 270 40 / 下弧 Q 270 180） -->
<path class="ad-active" data-edge="closed-open" d="M 196 90 Q 270 42 344 90" stroke="var(--error, light-dark(#dc2626, #f87171))" />
<text x="270" y="54" text-anchor="middle" font-size="12" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">連続失敗 ≥ 5</text>
<path class="ad-active" data-edge="half-closed" d="M 344 130 Q 270 178 196 130" stroke="var(--success, light-dark(#047857, #34d399))" />
<!-- 自己ループ（状態ノード上辺の外側） -->
<path class="ad-active" data-edge="closed-self" d="M 118 82 C 110 42, 162 42, 154 82" stroke="var(--chart-1, light-dark(#1d4ed8, #60a5fa))" />
```

#### (d) データ/パケット変換パイプライン（上段ステージ + 下段ミニデータ例並置）
```html
<!-- 上段ステージ（y = 32..84） -->
<g class="ad-node" data-node="stage-1">
  <rect class="ad-node-box" x="30" y="32" width="150" height="52" rx="8" />
  <text x="105" y="63" text-anchor="middle" font-size="13" font-weight="600" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">① Tokenizer</text>
</g>
<!-- 下段に Static-First で変換後の具体データを常時並置（y = 114..176） -->
<line x1="105" y1="84" x2="105" y2="114" stroke="var(--border, light-dark(#cbd5e1, #3f3f46))" stroke-dasharray="3 3" />
<g class="ad-node" data-node="snap-1">
  <rect class="ad-node-box" x="24" y="114" width="162" height="56" rx="6" />
  <text x="34" y="138" font-size="12" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" fill="var(--foreground, light-dark(#0f172a, #f4f4f5))">["let", "x", "=", "42"]</text>
  <text x="34" y="158" font-size="12" fill="var(--muted-foreground, light-dark(#475569, #a1a1aa))">線形トークン列</text>
</g>
```
