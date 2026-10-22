// The carousel of constructions on the landing page.
//
// Each slide's diagram is assembled bottom-up (CSS animations), then its operations are played:
// an operation (ω) leaves the application, travels down the edges of the diagram, changing
// shape at each combinator according to how it transforms the operation. Finally, it updates the leaves.
// Then the state is interpreted (γ):
// every leaf sends its interpretation up, each combinator combines those of its parts, and the
// root's reaches the application. When a slide has finished, the next one starts.
//
// Everything runs on one clock that stops while the carousel is paused or off screen, so pausing
// freezes the animation rather than skipping it.

(() => {
  const root = document.querySelector('.showcase');
  if (!root) return;

  const slides = [...root.querySelectorAll('.sc-slide')];
  const tabs = [...root.querySelectorAll('.sc-tab')];
  const playButton = root.querySelector('.sc-play');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const SVG = 'http://www.w3.org/2000/svg';

  // Timings, in milliseconds.
  const LEVEL = 110;        // assembling one level of the diagram (matches showcase.css)
  const SPEED = 0.08;       // how fast operations travel, in pixels per millisecond
  const PAUSE = 500;        // operations resting in their leaves before the state is interpreted
  const SWAP = 220;         // an operation fading out of its leaf before the interpretation pops in
  const POP = 300;          // the interpretation popping in (matches showcase.css)
  const REACH = 0.72;       // how far up its edge an interpretation goes while waiting to be combined
  const CONVERGE = 260;     // interpretations sliding together to be combined
  const FADE = 250;         // the interpretation merging into the application
  const GATHER = 600;       // the full interpretation showing at the root, before it rises
  const RISE = 750;         // the interpretation rising to the application, at least
  const BETWEEN = 800;      // between two operations
  const HOLD = 1200;        // after the last operation, before the next slide

  root.classList.add('enhanced');

  // ---------- The clock ----------

  let now = 0;
  let last = null;
  let userPaused = false;
  let visible = true;
  const timers = new Set();

  const running = () => !userPaused && visible;

  const frame = (t) => {
    if (last !== null && running()) now += Math.min(t - last, 64);
    last = t;
    for (const timer of [...timers]) timer.tick(now);
    updateProgress();
    requestAnimationFrame(frame);
  };

  // Calls `onTick(p)` with p going from 0 to 1 over `duration`, then resolves.
  const tween = (duration, onTick = () => {}) => new Promise((resolve) => {
    const start = now;
    const timer = {
      tick(t) {
        const p = Math.min(1, (t - start) / duration);
        onTick(p);
        if (p >= 1) { timers.delete(timer); resolve(); }
      },
      cancel() { timers.delete(timer); },
    };
    timers.add(timer);
  });

  const wait = (duration) => (duration > 0 ? tween(duration) : Promise.resolve());
  const ease = (p) => (p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2);

  // ---------- Slides ----------

  let current = 0;
  let generation = 0;
  let progressStart = 0;
  let progressLength = 1;

  class Cancelled extends Error {}

  const restartAnimation = (el, cls) => {
    el.classList.remove(cls);
    void el.getBoundingClientRect();
    el.classList.add(cls);
  };

  const parseSteps = (slide) => {
    try { return JSON.parse(slide.dataset.steps || '[]'); } catch { return []; }
  };

  // Assembling takes one step per level of the tree, plus the application box at the top.
  const buildTime = (slide) => {
    const app = slide.querySelector('.dg-app');
    const levels = Number.parseInt(app?.style.getPropertyValue('--h') || '0', 10);
    return levels * LEVEL + 380;
  };

  // ---------- Routes ----------
  //
  // An operation is one token until it becomes several: where `joint_product` updates both sides,
  // or a `traverse` emits a list. The deliveries of a step (one per leaf it updates) are merged into
  // a tree, sharing the part of the way where they go along the same edges as the same operation.
  // Each route node is the edge a token takes into a diagram node, with its label on that edge.
  //
  // Operations that a node sends along the same edge, like the list a `traverse` emits, travel
  // together as one linked bubble, stacked in order: a group of route nodes on one edge.

  const routeTree = (step) => {
    const root = { node: '', edge: 'in', label: step.op, children: [], state: null };
    for (const hop of step.hops) {
      let at = root;
      hop.path.forEach((_, k) => {
        const node = hop.path.slice(0, k + 1).join('.');
        const label = hop.labels[k];
        let next = at.children.find((c) => c.node === node && c.label === label);
        if (!next) {
          next = { node, edge: node, label, children: [], state: null };
          at.children.push(next);
        }
        at = next;
      });
      at.state = hop.state;
    }
    return root;
  };

  const edgeOf = (svg, route) => svg.querySelector(`[data-edge="${route.edge}"]`);
  const nodeOf = (svg, route) => svg.querySelector(`.dg-node[data-node="${route.node}"]`);
  const boxHeight = (node) => Number.parseFloat(node.querySelector('.dg-box').getAttribute('height'));

  const byEdge = (routes) => {
    const groups = [];
    for (const r of routes) {
      const group = groups.find((g) => g.edge === r.edge);
      if (group) group.members.push(r);
      else groups.push({ edge: r.edge, node: r.node, members: [r] });
    }
    return groups;
  };

  const groupOf = (route) => ({ edge: route.edge, node: route.node, members: [route] });
  const nextGroups = (group) => byEdge(group.members.flatMap((m) => m.children));
  const labelsOf = (group) => group.members.map((m) => m.label);
  // All members of a group enter the same node, so either all of them stop there or none does.
  const atLeaf = (group) => group.members.every((m) => !m.children.length);

  // How long a group takes from entering its edge until it, and everything it splits into, has
  // arrived.
  const routeTime = (svg, group) => {
    const height = boxHeight(nodeOf(svg, group));
    const travel = edgeOf(svg, group).getTotalLength() / SPEED;
    if (atLeaf(group)) return travel + height / 2 / SPEED;
    return travel + height / SPEED + Math.max(...nextGroups(group).map((g) => routeTime(svg, g)));
  };

  const readTime = (svg) => {
    const up = upSchedule(svg, 0);
    return PAUSE + SWAP + POP + up.ready.get('') + GATHER + Math.max(RISE, up.edgeTo('').getTotalLength() / SPEED) + FADE;
  };

  const slideLength = (slide, steps) => {
    const svg = slide.querySelector('svg.dg');
    let total = buildTime(slide) + HOLD - BETWEEN;
    for (const step of steps) total += routeTime(svg, groupOf(routeTree(step))) + readTime(svg) + BETWEEN;
    return total;
  };

  const setChip = (text, value) => {
    text.textContent = value;
    const bg = text.previousElementSibling;
    if (!bg) return;
    const width = text.getComputedTextLength() + 20;
    bg.setAttribute('width', width.toFixed(1));
    bg.setAttribute('x', (-width / 2).toFixed(1));
  };

  // Puts a slide back into its initial state, before any operation.
  const reset = (slide) => {
    slide.querySelectorAll('.dg-state-text').forEach((t) => setChip(t, t.dataset.initial));
    const view = slide.querySelector('.dg-view');
    if (view) view.textContent = view.dataset.initial;
    slide.querySelectorAll('.sc-ops li').forEach((li) => li.classList.remove('done', 'running'));
    slide.querySelector('.dg-tokens')?.replaceChildren();
    slide.querySelectorAll('.pulse, .changed').forEach((el) => el.classList.remove('pulse', 'changed'));
    slide.querySelectorAll('.dg-edge').forEach((edge) => { edge.lit = 0; edge.classList.remove('lit'); });
    slide.querySelector('svg.dg')?.classList.remove('reading');
  };

  // Shows the result of every operation at once, without animation.
  const finish = (slide, steps) => {
    for (const step of steps) {
      for (const hop of step.hops) {
        const leaf = slide.querySelector(`.dg-node[data-node="${hop.path.join('.')}"] .dg-state-text`);
        if (leaf) setChip(leaf, hop.state);
      }
    }
    const view = slide.querySelector('.dg-view');
    if (view && steps.length) view.textContent = steps[steps.length - 1].view;
    slide.querySelectorAll('.sc-ops li').forEach((li) => li.classList.add('done'));
  };

  // A bubble travelling along the diagram. Operations (`op`, marked ω) travel down; the
  // interpretation of the whole state (`interp`, marked γ) travels up to the application.
  const GLYPH = { op: 'ω', interp: 'γ' };

  const ROW = 23;           // between the rows of a linked bubble

  const svgEl = (name, cls, attrs = {}) => {
    const el = document.createElementNS(SVG, name);
    el.setAttribute('class', cls);
    for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v);
    return el;
  };

  // A bubble at a point of the diagram, with one row per operation: several rows are linked in a
  // frame, and travel as one.
  const makeToken = (layer, kind) => {
    // The outer group is positioned by its transform attribute; the inner one is free for CSS
    // animations, which would otherwise override that position.
    const g = svgEl('g', `dg-token ${kind}`);
    const body = svgEl('g', 'dg-token-body');
    g.append(body);
    layer.append(g);

    const labels = (values) => {
      body.replaceChildren();
      const n = values.length;
      const frame = svgEl('rect', 'dg-token-frame', { x: -15, rx: 3 });
      const link = svgEl('rect', 'dg-token-link', { x: -2, width: 4, y: -(n - 1) * ROW / 2, height: (n - 1) * ROW });
      if (n > 1) body.append(frame, link);
      let widest = 20;
      values.forEach((value, i) => {
        const y = (i - (n - 1) / 2) * ROW;
        const bg = svgEl('rect', 'dg-token-bg', { x: -10, y: y - 10, height: 20, rx: 3 });
        const dot = svgEl('circle', 'dg-token-dot', { cy: y, r: 10 });
        const glyph = svgEl('text', 'dg-token-glyph', { y: y + 4 });
        glyph.textContent = GLYPH[kind];
        const text = svgEl('text', 'dg-token-text', { x: 15, y: y + 4 });
        text.textContent = value;
        body.append(bg, dot, glyph, text);
        const width = value ? text.getComputedTextLength() + 34 : 20;
        bg.setAttribute('width', width.toFixed(1));
        widest = Math.max(widest, width);
      });
      frame.setAttribute('y', (-(n - 1) * ROW / 2 - 14).toFixed(1));
      frame.setAttribute('height', ((n - 1) * ROW + 28).toFixed(1));
      frame.setAttribute('width', (widest + 10).toFixed(1));
    };

    return {
      g,
      labels,
      label(value) { labels([value]); },
      at(point) { g.setAttribute('transform', `translate(${point.x.toFixed(1)} ${point.y.toFixed(1)})`); },
    };
  };

  // Lights an edge while at least one token is on it.
  const light = (edge, on) => {
    edge.lit = (edge.lit || 0) + (on ? 1 : -1);
    edge.classList.toggle('lit', edge.lit > 0);
  };

  // Calls `onTick(t)` with the clock time on every frame, until it returns true.
  const follow = (onTick) => new Promise((resolve) => {
    const timer = {
      tick(t) { if (onTick(t)) { timers.delete(timer); resolve(); } },
      cancel() { timers.delete(timer); },
    };
    timers.add(timer);
  });

  // Resolves when the clock reaches `time`.
  const until = (time) => follow((t) => t >= time);

  // A bubble's way through the diagram from `group` on, for as long as it stays one bubble:
  // edges, and passes down through nodes, each scheduled on the clock, with what happens on the
  // way. It ends at a leaf, or at the bottom of a node that sends operations along several edges.
  //
  // Scheduling the whole way in advance, rather than one piece after another, keeps the bubble
  // moving at a constant speed: it never waits a frame between two pieces.
  const itinerary = (svg, group, start) => {
    const parts = [];
    const events = [];
    let t = start;
    for (let g = group; ;) {
      const edge = edgeOf(svg, g);
      const length = edge.getTotalLength();
      parts.push({ t0: t, t1: t + length / SPEED, edge, point: (p) => edge.getPointAtLength(length * p) });
      t += length / SPEED;
      const node = nodeOf(svg, g);
      events.push({ time: t, run: () => restartAnimation(node, 'pulse') });
      const top = edge.getPointAtLength(length);
      if (atLeaf(g)) {
        // Into the leaf, where the operations are applied.
        const depth = boxHeight(node) / 2;
        parts.push({ t0: t, t1: t + depth / SPEED, point: (p) => ({ x: top.x, y: top.y + depth * p }) });
        return { parts, events, end: t + depth / SPEED, last: g };
      }

      // Down through the node. Halfway, the combinator rewrites the operations: into one or more
      // on the same edge, which stay one bubble, or onto several edges, where the bubble splits.
      const height = boxHeight(node);
      const through = height / SPEED;
      parts.push({ t0: t, t1: t + through, point: (p) => ({ x: top.x, y: top.y + height * p }) });
      const next = nextGroups(g);
      if (next.length > 1) return { parts, events, end: t + through, last: g };
      events.push({ time: t + through / 2, run: (token) => token.labels(labelsOf(next[0])) });
      t += through;
      g = next[0];
    }
  };

  // Moves a token along an itinerary, lighting each edge while the token is on it.
  const run = (token, plan) => {
    let next = 0;
    let lit = null;
    return follow((t) => {
      while (next < plan.events.length && plan.events[next].time <= t) plan.events[next++].run(token);
      const part = plan.parts.find((p) => t < p.t1) || plan.parts[plan.parts.length - 1];
      token.at(part.point(Math.max(0, Math.min(1, (t - part.t0) / (part.t1 - part.t0)))));
      const edge = t >= part.t0 && t < plan.end ? part.edge || null : null;
      if (edge !== lit) {
        if (lit) light(lit, false);
        if (edge) light(edge, true);
        lit = edge;
      }
      return t >= plan.end;
    });
  };

  // Plays one group, starting at clock time `start`, with `token` at the start of its edge.
  // Operations that reach a leaf stay there, in `landed`, until the state is interpreted.
  const deliver = async (svg, group, token, start, landed, check) => {
    const plan = itinerary(svg, group, start);
    await run(token, plan);
    check();
    const stop = plan.last;

    if (atLeaf(stop)) {
      const node = nodeOf(svg, stop);
      const chip = node.querySelector('.dg-state-text');
      const state = stop.members.map((m) => m.state).filter((st) => st !== null).pop();
      if (chip && state !== undefined) {
        setChip(chip, state);
        restartAnimation(node, 'changed');
      }
      // A later operation to the same leaf takes the place of an earlier one.
      landed.get(stop.node)?.g.remove();
      landed.set(stop.node, token);
      return;
    }

    // The operations go separate ways: one bubble per edge, all leaving the bottom of the node now.
    token.g.remove();
    const layer = svg.querySelector('.dg-tokens');
    await Promise.all(nextGroups(stop).map((next) => {
      const bubble = makeToken(layer, 'op');
      bubble.labels(labelsOf(next));
      bubble.at(edgeOf(svg, next).getPointAtLength(0));
      return deliver(svg, next, bubble, plan.end, landed, check);
    }));
  };

  const send = async (slide, step, check) => {
    const svg = slide.querySelector('svg.dg');
    const group = groupOf(routeTree(step));
    const token = makeToken(svg.querySelector('.dg-tokens'), 'op');
    token.labels(labelsOf(group));
    token.at(edgeOf(svg, group).getPointAtLength(0));
    const landed = new Map();
    await deliver(svg, group, token, now, landed, check);
    return landed;
  };

  // When each node's interpretation enters its box (`begin`) and leaves its top (`ready`), if
  // the leaves' interpretations start rising from the middle of the leaves at `start`. A node with
  // one part takes over its part's as it arrives; a node with several waits until all of theirs
  // are close, then they slide together and are combined.
  const upSchedule = (svg, start) => {
    const keys = [...svg.querySelectorAll('.dg-node')].map((n) => n.dataset.node);
    const node = (key) => svg.querySelector(`.dg-node[data-node="${key}"]`);
    const parts = (key) => keys.filter((k) => {
      if (k === key) return false;
      if (key === '') return k !== '' && !k.includes('.');
      return k.startsWith(`${key}.`) && !k.slice(key.length + 1).includes('.');
    });
    const edgeTo = (key) => svg.querySelector(`[data-edge="${key === '' ? 'in' : key}"]`);
    const length = (key) => edgeTo(key).getTotalLength();
    const begin = new Map();
    const ready = new Map();
    const time = (key) => {
      if (!ready.has(key)) {
        const ps = parts(key);
        const height = boxHeight(node(key));
        let b;
        if (!ps.length) b = start;
        else if (ps.length === 1) b = time(ps[0]) + length(ps[0]) / SPEED;
        else b = Math.max(...ps.map((k) => time(k) + REACH * length(k) / SPEED)) + CONVERGE;
        begin.set(key, b);
        ready.set(key, b + (ps.length ? height : height / 2) / SPEED);
      }
      return ready.get(key);
    };
    time('');
    return { keys, node, parts, edgeTo, begin, ready };
  };

  // The application reads the new interpretation. The operations rest in the leaves they updated,
  // then fade out, and every leaf's interpretation pops in, since `interpret` takes the whole state. They rise, each combinator combining or rewriting them, and
  // the root's, the interpreted state, rises into the application.
  const readBack = async (slide, step, landed, check) => {
    const svg = slide.querySelector('svg.dg');
    const layer = svg.querySelector('.dg-tokens');
    const start = now;
    const up = upSchedule(svg, start + PAUSE + SWAP + POP);

    // What each node reads as after this step, by path (computed in `Site/Carousel.lean`).
    const reads = step.reads || {};
    const readsAs = (key) => reads[key] ?? (key === '' ? step.view : '');

    // The operations fade out of their leaves, then every leaf's interpretation pops in.
    await until(start + PAUSE);
    check();
    svg.classList.add('reading');
    for (const token of landed.values()) token.g.classList.add('gone');
    await until(start + PAUSE + SWAP);
    check();
    for (const token of landed.values()) token.g.remove();
    const leaves = new Map();
    for (const key of up.keys.filter((k) => !up.parts(k).length)) {
      const top = up.edgeTo(key).getPointAtLength(up.edgeTo(key).getTotalLength());
      const token = makeToken(layer, 'interp');
      token.label(readsAs(key));
      token.at({ x: top.x, y: top.y + boxHeight(up.node(key)) / 2 });
      restartAnimation(token.g, 'appear');
      leaves.set(key, token);
    }

    // One bubble per node, up through its box and its edge. A leaf's is the token above; a node
    // with one part takes over its part's, rewriting it halfway up the box if its interpretation
    // does something; a node with several parts starts with them combined.
    const bubble = async (key) => {
      const parts = up.parts(key);
      const leaf = !parts.length;
      const parent = key.includes('.') ? key.slice(0, key.lastIndexOf('.')) : '';
      const edge = up.edgeTo(key);
      const length = edge.getTotalLength();
      const top = edge.getPointAtLength(length);
      const height = boxHeight(up.node(key));
      const begin = up.begin.get(key);
      const ready = up.ready.get(key);
      const own = readsAs(key);
      const incoming = parts.length === 1 ? readsAs(parts[0]) : own;
      const from = leaf ? top.y + height / 2 : top.y + height;

      await until(begin);
      check();
      let token = leaves.get(key);
      if (!token) {
        token = makeToken(layer, 'interp');
        token.label(incoming);
        token.at({ x: top.x, y: from });
      }
      if (parts.length > 1) restartAnimation(up.node(key), 'pulse');

      const plan = { parts: [], events: [], end: ready };
      plan.parts.push({ t0: begin, t1: ready, point: (p) => ({ x: top.x, y: from + (top.y - from) * p }) });
      if (incoming !== own) {
        plan.events.push({
          time: (begin + ready) / 2,
          run: (t) => { t.label(own); restartAnimation(up.node(key), 'pulse'); },
        });
      }
      if (key === '') {
        // The root: show the interpreted state, then rise into the application.
        const end = ready + GATHER + Math.max(RISE, length / SPEED);
        plan.parts.push({ t0: ready + GATHER, t1: end, edge, point: (p) => edge.getPointAtLength(length * (1 - ease(p))) });
        plan.end = end;
      } else if (up.parts(parent).length > 1) {
        // Wait a little below the parent, folded to just γ so that the waiting bubbles do not cover
        // one another, then slide in together to be combined.
        const merge = up.begin.get(parent);
        const near = ready + REACH * length / SPEED;
        plan.parts.push({ t0: ready, t1: near, edge, point: (p) => edge.getPointAtLength(length * (1 - REACH * p)) });
        plan.events.push({ time: near, run: (t) => t.label('') });
        plan.parts.push({ t0: merge - CONVERGE, t1: merge, edge, point: (p) => edge.getPointAtLength(length * (1 - REACH - (1 - REACH) * p)) });
        plan.end = merge;
      } else {
        const end = ready + length / SPEED;
        plan.parts.push({ t0: ready, t1: end, edge, point: (p) => edge.getPointAtLength(length * (1 - p)) });
        plan.end = end;
      }
      await run(token, plan);
      check();
      // The parent's bubble takes over from here, at this point and in this frame.
      if (key !== '') { token.g.remove(); return; }

      // Into the application, which now shows the interpreted state.
      svg.querySelector('.dg-view').textContent = step.view;
      restartAnimation(svg.querySelector('.dg-app'), 'pulse');
      svg.classList.remove('reading');
      token.g.classList.add('gone');
      const at = edge.getPointAtLength(0);
      await run(token, { parts: [{ t0: plan.end, t1: plan.end + FADE, point: (p) => ({ x: at.x, y: at.y - 14 * p }) }], events: [], end: plan.end + FADE });
      token.g.remove();
    };

    await Promise.all(up.keys.map(bubble));
  };

  const play = async (slide, steps, gen) => {
    const check = () => { if (gen !== generation) throw new Cancelled(); };
    restartAnimation(slide, 'building');
    await wait(buildTime(slide));
    check();
    const items = slide.querySelectorAll('.sc-ops li');
    for (let s = 0; s < steps.length; s++) {
      const step = steps[s];
      items[s]?.classList.add('running');
      const landed = await send(slide, step, check);
      check();
      await readBack(slide, step, landed, check);
      check();
      items[s]?.classList.replace('running', 'done');
      await wait(s < steps.length - 1 ? BETWEEN : HOLD);
      check();
    }
    show(current + 1);
  };

  function show(index, { focus = false } = {}) {
    const n = slides.length;
    current = ((index % n) + n) % n;
    generation++;
    for (const timer of [...timers]) timer.cancel();

    slides.forEach((slide, i) => {
      const active = i === current;
      slide.classList.toggle('active', active);
      slide.setAttribute('aria-hidden', active ? 'false' : 'true');
      slide.inert = !active;
    });
    tabs.forEach((tab, i) => {
      const active = i === current;
      tab.classList.toggle('active', active);
      tab.setAttribute('aria-selected', active ? 'true' : 'false');
      tab.tabIndex = active ? 0 : -1;
      tab.style.setProperty('--progress', '0');
    });
    if (focus) tabs[current].focus();
    // Keep the active tab in view when the tab strip scrolls.
    const strip = tabs[current].parentElement;
    const tab = tabs[current];
    if (strip.scrollWidth > strip.clientWidth) {
      strip.scrollTo({ left: tab.offsetLeft - (strip.clientWidth - tab.offsetWidth) / 2, behavior: 'smooth' });
    }

    const slide = slides[current];
    const steps = parseSteps(slide);
    reset(slide);
    progressStart = now;
    progressLength = slideLength(slide, steps);

    if (reduceMotion.matches) {
      finish(slide, steps);
      progressLength = Infinity;
      return;
    }
    play(slide, steps, generation).catch((e) => { if (!(e instanceof Cancelled)) throw e; });
  }

  function updateProgress() {
    const tab = tabs[current];
    if (!tab) return;
    const p = Number.isFinite(progressLength) ? Math.min(1, (now - progressStart) / progressLength) : 0;
    tab.style.setProperty('--progress', p.toFixed(4));
  }

  const setPaused = (paused) => {
    userPaused = paused;
    root.classList.toggle('paused', paused);
    playButton.setAttribute('aria-label', paused ? 'Play the animation' : 'Pause the animation');
  };

  const updateFrozen = () => root.classList.toggle('frozen', !running());

  // ---------- Controls ----------

  tabs.forEach((tab, i) => {
    tab.addEventListener('click', () => show(i));
    tab.addEventListener('keydown', (e) => {
      const keys = { ArrowRight: 1, ArrowLeft: -1 };
      if (e.key in keys) { e.preventDefault(); show(current + keys[e.key], { focus: true }); }
      if (e.key === 'Home') { e.preventDefault(); show(0, { focus: true }); }
      if (e.key === 'End') { e.preventDefault(); show(slides.length - 1, { focus: true }); }
    });
  });
  root.querySelector('.sc-prev').addEventListener('click', () => show(current - 1));
  root.querySelector('.sc-next').addEventListener('click', () => show(current + 1));
  playButton.addEventListener('click', () => { setPaused(!userPaused); updateFrozen(); });

  const stage = root.querySelector('.sc-stage');

  // Swipe between slides on touch screens.
  let touchX = null;
  stage.addEventListener('touchstart', (e) => { touchX = e.touches[0].clientX; }, { passive: true });
  stage.addEventListener('touchend', (e) => {
    if (touchX === null) return;
    const dx = e.changedTouches[0].clientX - touchX;
    touchX = null;
    if (Math.abs(dx) > 50) show(current + (dx < 0 ? 1 : -1));
  });

  // Stop the clock while the carousel is off screen.
  if ('IntersectionObserver' in window) {
    new IntersectionObserver((entries) => {
      visible = entries[0].isIntersecting;
      updateFrozen();
    }, { threshold: 0.15 }).observe(root);
  }

  reduceMotion.addEventListener('change', () => show(current));

  setPaused(false);
  show(0);
  requestAnimationFrame(frame);
})();
