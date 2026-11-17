# インタラクティブ図解 実装パターン集（HTML / SVG / Canvas / JS）

本ドキュメントは、認知負荷理論と直接操作原則を満たすインタラクティブ図解を実装するための、再利用可能な最小コードパターンを提供する。

---

## 1. 本文・数式・SVG図解の双方向ホバーハイライト（`data-key` パターン）

**目的**: Split-Attention Effect（注意分割効果）を排除し、独立した凡例ボックス（Legend）を廃止する（Amit Patel, 2021; Chandler & Sweller, 1992）。

```html
<!-- スタイル定義：data-keyのハイライト連動と意味的色分けピル -->
<style>
  [data-key] {
    transition: opacity 0.15s ease, filter 0.15s ease, transform 0.15s ease;
    cursor: pointer;
  }
  .inline-term {
    padding: 0.1em 0.45em;
    border-radius: 0.35rem;
    font-weight: 600;
    border-bottom: 2px solid currentColor;
  }
  /* ホバー中、非該当のdata-key要素を減光（Color Restraint / Signaling） */
  body.is-highlighting [data-key]:not(.is-active-key) {
    opacity: 0.25;
  }
  body.is-highlighting [data-key].is-active-key {
    filter: drop-shadow(0 0 6px currentColor);
  }
</style>

<!-- 本文＋数式＋SVG図解での使用例 -->
<p class="text-sm leading-relaxed">
  探索アルゴリズムは、<span class="inline-term text-amber-500 bg-amber-500/10" data-key="frontier">フロンティア（Open Set）</span>
  から最小コスト $f(n) =$ <span class="inline-term text-sky-500 bg-sky-500/10" data-key="g-cost">$g(n)$ 実コスト</span> $+$
  <span class="inline-term text-emerald-500 bg-emerald-500/10" data-key="h-cost">$h(n)$ 推定ヒューリスティック</span> を持つノードを選択します。
</p>

<svg viewBox="0 0 400 120" class="w-full h-auto">
  <g data-key="g-cost" class="text-sky-500">
    <line x1="30" y1="60" x2="180" y2="60" stroke="currentColor" stroke-width="3" />
    <text x="105" y="48" fill="currentColor" font-size="12" text-anchor="middle">g(n) = 4.2</text>
  </g>
  <circle data-key="frontier" cx="180" cy="60" r="10" class="text-amber-500" fill="currentColor" />
  <g data-key="h-cost" class="text-emerald-500">
    <line x1="180" y1="60" x2="350" y2="60" stroke="currentColor" stroke-width="3" stroke-dasharray="5,5" />
    <text x="265" y="48" fill="currentColor" font-size="12" text-anchor="middle">h(n) = 3.1</text>
  </g>
</svg>

<script>
  // 双方向ホバーハイライト（15行で完結）
  document.addEventListener('pointerover', (e) => {
    const target = e.target.closest('[data-key]');
    if (!target) return;
    const key = target.getAttribute('data-key');
    document.body.classList.add('is-highlighting');
    document.querySelectorAll(`[data-key="${key}"]`).forEach(el => el.classList.add('is-active-key'));
  });
  document.addEventListener('pointerout', (e) => {
    const target = e.target.closest('[data-key]');
    if (!target) return;
    document.body.classList.remove('is-highlighting');
    document.querySelectorAll('.is-active-key').forEach(el => el.classList.remove('is-active-key'));
  });
</script>
```

---

## 2. インライン数値スクラブ（Tangle風 Scrubbable Numbers）

**目的**: 入力フォームを分離せず、文中の前提数値を直接左右ドラッグして結論への波及をリアルタイムに検証させる（Bret Victor, 2011 *"Explorable Explanations" / "Tangle"*）。

```html
<style>
  .scrubbable {
    display: inline-block;
    color: #3b82f6;
    font-weight: 700;
    border-bottom: 2px dashed #3b82f6;
    cursor: ew-resize;
    user-select: none;
    padding: 0 0.2em;
    border-radius: 0.25rem;
    background: rgba(59, 130, 246, 0.1);
  }
  .scrubbable:hover {
    background: rgba(59, 130, 246, 0.2);
  }
</style>

<p class="text-sm">
  伝達ミス率が <span class="scrubbable" data-var="noise" data-min="0" data-max="50" data-step="1" data-value="5">5%</span>
  のとき、10世代後の支配戦略は <strong id="winner-label">Copykitten（寛容なしっぺ返し）</strong> になります。
  <span class="text-xs opacity-70">（← 数値を左右にドラッグ）</span>
</p>

<script>
  function initScrubbables(onChange) {
    document.querySelectorAll('.scrubbable').forEach(el => {
      let startX = 0, startVal = 0;
      const min = parseFloat(el.dataset.min ?? 0);
      const max = parseFloat(el.dataset.max ?? 100);
      const step = parseFloat(el.dataset.step ?? 1);

      el.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        el.setPointerCapture(e.pointerId);
        startX = e.clientX;
        startVal = parseFloat(el.dataset.value);
      });

      el.addEventListener('pointermove', (e) => {
        if (!el.hasPointerCapture(e.pointerId)) return;
        const dx = e.clientX - startX;
        const raw = startVal + Math.round(dx / 4) * step;
        const clamped = Math.max(min, Math.min(max, raw));
        el.dataset.value = clamped;
        el.textContent = `${clamped}%`;
        onChange(el.dataset.var, clamped);
      });
    });
  }
</script>
```

---

## 3. 境界制約付き直接操作ハンドル（Direct Manipulation + Combinators）

**目的**: 外部のX/Yスライダーを廃し、キャンバス上のオブジェクト自体を直接掴んで操作させるとともに、`.clamped()` で不正状態への突入を防ぐ（Shneiderman, 1983; Amit Patel, 2025）。

```javascript
/**
 * 2Dドラッグハンドルのバインディング（SVG要素用、境界クランプ＆丸め制約付き）
 */
function makeDraggable(svgElement, handleEl, initialPos, options = {}) {
  const {
    minX = 0, maxX = 400,
    minY = 0, maxY = 250,
    step = 1,
    lockY = false,
    onDrag = () => {}
  } = options;

  const state = { x: initialPos.x, y: initialPos.y };

  function toSvgPoint(clientX, clientY) {
    const pt = svgElement.createSVGPoint();
    pt.x = clientX;
    pt.y = clientY;
    return pt.matrixTransform(svgElement.getScreenCTM().inverse());
  }

  function applyConstraints(rawX, rawY) {
    const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v / step) * step));
    state.x = clamp(rawX, minX, maxX);
    state.y = lockY ? initialPos.y : clamp(rawY, minY, maxY);
    handleEl.setAttribute('transform', `translate(${state.x}, ${state.y})`);
    onDrag(state);
  }

  handleEl.style.cursor = 'grab';
  handleEl.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    handleEl.setPointerCapture(e.pointerId);
    handleEl.style.cursor = 'grabbing';
  });

  handleEl.addEventListener('pointermove', (e) => {
    if (!handleEl.hasPointerCapture(e.pointerId)) return;
    const loc = toSvgPoint(e.clientX, e.clientY);
    applyConstraints(loc.x, loc.y);
  });

  handleEl.addEventListener('pointerup', (e) => {
    if (handleEl.hasPointerCapture(e.pointerId)) {
      handleEl.releasePointerCapture(e.pointerId);
    }
    handleEl.style.cursor = 'grab';
  });

  applyConstraints(state.x, state.y);
  return { getState: () => state, setState: (x, y) => applyConstraints(x, y) };
}
```

---

## 4. 抽象化の梯子（Rung 1 全時間軌跡 ＋ ホバーによる Rung 0 具体状態の重畳）＋ プリセットジャンパー

**目的**: 「Play/Pause だけのアニメーション」を廃し、初期状態で全時間の軌跡（Rung 1）を一目で見せつつ、軌跡上のホバーでその時刻の具体的姿勢（Rung 0）へ即座に降りる（Bret Victor, 2011 *"Up and Down the Ladder of Abstraction"*）。さらにエッジケースへ誘導するプリセットボタンを併設する。

```html
<!-- エッジケース・プリセットジャンパー（Gotcha #5 回避） -->
<div class="flex flex-wrap items-center gap-2 mb-3">
  <span class="text-xs font-medium opacity-75">プリセット検証:</span>
  <button type="button" data-preset="1.5" class="preset-btn px-2.5 py-1 text-xs rounded-md border">
    1.5°（滑らかに収束）
  </button>
  <button type="button" data-preset="6.5" class="preset-btn px-2.5 py-1 text-xs rounded-md border">
    6.5°（臨界閾値・壁面滑走）
  </button>
  <button type="button" data-preset="8.0" class="preset-btn px-2.5 py-1 text-xs rounded-md border text-amber-500">
    8.0°（異常ピボット振動 / エッジケース）
  </button>
</div>
```

**設計のポイント**:
1. キャンバスには最初から $t = 0 \dots T$ の**全軌跡曲線（Rung 1）**を静的に描画しておく（Static-First）。
2. ユーザーが軌跡グラフ上でマウスをホバー（またはタイムスライダーをスクラブ）した座標 $t_{\text{hover}}$ に対してのみ、その時刻における**オブジェクトの具体的な向き・速度ベクトル・内部状態（Rung 0）**をハイライト重畳する。
3. プリセットボタンをクリックすると、スライダー値が該当するエッジケース値へ更新され、同時に「なぜこの値で挙動が変わるのか」の1行解説コールアウトが切り替わるように実装する。

---

## 5. 事前予測ゲート（"Place Your Bets" / "You Draw It" パターン）

**目的**: 反直観的な結果を見せる前にユーザーに予測をコミットさせ、認知的葛藤（Expectation Shock）によってメンタルモデルを更新させる（Nicky Case, 2018; Hohman et al., 2020 *Distill*）。

```html
<div id="prediction-gate" class="p-4 rounded-lg border mb-4">
  <p class="text-sm font-semibold mb-2">
    🤔 予測してみてください：通信ノイズが 0% から 5% に増えたとき、トーナメントで優勝するのはどの戦略でしょうか？
  </p>
  <div class="flex flex-wrap gap-2">
    <button type="button" data-bet="copycat" class="bet-btn px-3 py-1.5 text-xs rounded border">
      Copycat（しっぺ返し）
    </button>
    <button type="button" data-bet="copykitten" class="bet-btn px-3 py-1.5 text-xs rounded border">
      Copykitten（2回裏切られるまで許す）
    </button>
    <button type="button" data-bet="cheat" class="bet-btn px-3 py-1.5 text-xs rounded border">
      Always Cheat（常に裏切る）
    </button>
  </div>
  <div id="prediction-feedback" class="hidden mt-3 text-xs p-3 rounded bg-emerald-500/10">
    <!-- ユーザーがボタンを押した後にのみ表示し、シミュレーションのロックを解除する -->
  </div>
</div>
```

---

## 6. 決定論的シード付き疑似乱数（Flicker 防止）

**目的**: スライダーをわずかに動かした際、`Math.random()` によって粒子やグラフが毎回全く違う配置に飛び跳ねる（Non-Deterministic Flicker: Gotcha #8）のを防ぐ。

```javascript
/**
 * シード固定の決定論的乱数生成器（Mulberry32）
 * インタラクティブな再描画ループ内では必ず Math.random() の代わりにこれを使用する
 */
function createSeededRandom(seed = 42) {
  let a = seed >>> 0;
  return function nextRandom() {
    let t = (a += 0x6D2B79F5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
```
