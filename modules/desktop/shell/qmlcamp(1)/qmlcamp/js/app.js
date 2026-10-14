// =============================================================================
//  QMLCamp app: hash router + views (home, module, theory, lab, quiz, review, verify)
//  Block types, like freeCodeCamp: theory (lessons + questions), lab (build to user
//  stories, pass/fail tests), quiz (practice test), review (cheat sheet).
// =============================================================================
(function () {
'use strict';
const cleanups = [];
const C = window.QMLCAMP, $app = document.getElementById('app');
const { createEditor, esc } = window.QmlEditor;
const { makeKit, Fail } = window.QmlTestKit;

// ------------------------------------------------------------------ progress (localStorage, optional)
const KEY = 'qmlcamp.v1';
let prog = { done: {}, files: {}, q: {}, last: {}, lastCourse: null };
try { prog = Object.assign(prog, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) {}
const saveProg = () => { try { localStorage.setItem(KEY, JSON.stringify(prog)); } catch (e) {} };
const isDone = id => !!prog.done[id];
const markDone = id => { prog.done[id] = true; saveProg(); };

const h = (tag, attrs, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (k === 'class') e.className = v; else if (k === 'html') e.innerHTML = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else e.setAttribute(k, v);
  }
  for (const c of kids.flat()) if (c !== null && c !== undefined) e.append(c.nodeType ? c : document.createTextNode(c));
  return e;
};
// courses: other languages can push their own { id, title, desc, modules, upcoming } into QMLCAMP.courses
C.courses = C.courses || [];
if (!C.courses.some(c => c.id === 'qml')) C.courses.unshift({ id: 'qml', title: 'QML Foundations', desc: 'Learn the whole QML language and build a Quickshell Dynamic Island.', modules: C.modules, upcoming: C.upcoming || [] });
let course = C.courses[0];
const allBlocks = (c) => (c || course).modules.flatMap(m => m.blocks);
const everyBlock = () => C.courses.flatMap(c => allBlocks(c));
const blockById = id => { for (const c of C.courses) for (const m of c.modules) for (const b of m.blocks) if (b.id === id) return [m, b, c]; return [null, null, null]; };
const moduleById = id => { for (const c of C.courses) for (const m of c.modules) if (m.id === id) return [m, c]; return [null, null]; };
const labelOf = (c, route) => {          // "Module 5 > Toggle switch" for a #/m/.. or #/b/.. route
  const [kind, id] = String(route || '').replace(/^#\/?/, '').split('/');
  if (kind === 'b') { const [m, b] = blockById(id); if (b) return 'Module ' + (c.modules.indexOf(m) + 1) + ' > ' + b.title; }
  if (kind === 'm') { const [m] = moduleById(id); if (m) return 'Module ' + (c.modules.indexOf(m) + 1) + ' > ' + m.title; }
  return null;
};
const resumeFor = c => {                 // where "Continue" goes for a course: last visited page, else the first block
  const last = prog.last && prog.last[c.id];
  if (last && labelOf(c, last)) return { href: last, label: labelOf(c, last), started: true };
  const m = c.modules[0], b = m && m.blocks[0];
  return b ? { href: '#/b/' + b.id, label: 'Module 1 > ' + b.title, started: false } : { href: '#/c/' + c.id, label: c.title, started: false };
};
const TYPE_LABEL = { theory: 'Theory', lab: 'Lab', quiz: 'Quiz', review: 'Review' };

function updateOverall(welcome) {
  const all = allBlocks(), d = all.filter(b => isDone(b.id)).length, el = document.getElementById('overall');
  el.style.display = welcome ? 'none' : '';
  el.textContent = course.title + ': ' + d + ' of ' + all.length + ' blocks complete';
}

// ------------------------------------------------------------------ router
function route() {
  cleanups.splice(0).forEach(f => f());   // dispose runtimes of the previous view
  $app.style.maxWidth = '';
  const hash = location.hash.replace(/^#\/?/, '');
  const [kind, id] = hash.split('/');
  window.scrollTo(0, 0);
  $app.innerHTML = '';
  if (kind === 'c') course = C.courses.find(c => c.id === id) || course;
  else if (kind === 'm') course = moduleById(id)[1] || course;
  else if (kind === 'b') course = blockById(id)[2] || course;
  if ((kind === 'm' && moduleById(id)[0]) || (kind === 'b' && blockById(id)[1])) {   // remember the last visited page of this course
    prog.last = prog.last || {}; prog.last[course.id] = '#/' + hash; prog.lastCourse = course.id; saveProg();
  }
  const welcome = !(kind === 'c' || kind === 'm' || kind === 'b' || kind === 'verify');
  updateOverall(welcome);
  if (kind === 'c') return viewCourse(id);
  if (kind === 'm') return viewModule(id);
  if (kind === 'b') return viewBlock(id);
  if (kind === 'verify') return viewVerify();
  viewWelcome();
}
window.addEventListener('hashchange', route);

// ------------------------------------------------------------------ home
function viewWelcome() {
  const lastC = C.courses.find(c => c.id === prog.lastCourse) || null, hero = lastC ? resumeFor(lastC) : null;
  $app.append(h('div', { class: 'page', style: 'max-width:1100px' },
    h('h1', {}, 'Welcome to QMLCamp'),
    h('p', {}, 'Learn by building. Pick a course, or carry on where you stopped. Everything runs offline in your browser.'),
    hero && hero.started ? h('div', { class: 'card', style: 'margin:18px 0;border-color:var(--ok,#4cd964)' },
      h('div', { class: 'dim', style: 'color:var(--dim);font-size:13px' }, lastC.title),
      h('h3', {}, 'Where you left off'), h('p', {}, hero.label),
      h('a', { class: 'btn', href: hero.href }, 'Continue: ' + hero.label)) : null,
    h('h2', {}, C.courses.length > 1 ? 'Courses' : 'Course'),
    h('div', { class: 'mods' }, C.courses.map(c => {
      const all = allBlocks(c), d = all.filter(b => isDone(b.id)).length, r = resumeFor(c);
      return h('div', { class: 'card' }, h('h3', {}, c.title), h('p', {}, c.desc),
        h('div', { class: 'bar' }, h('i', { style: 'width:' + (all.length ? 100 * d / all.length : 0) + '%' })),
        h('div', { style: 'font-size:13px;color:var(--dim);margin-bottom:10px' }, c.modules.length + ' modules, ' + d + ' of ' + all.length + ' blocks complete'),
        h('div', { class: 'toolbar' }, h('a', { class: 'btn sm', href: r.href }, (r.started ? 'Continue: ' : 'Start: ') + r.label), h('a', { class: 'btn sm ghost', href: '#/c/' + c.id }, 'All modules')));
    })),
    h('p', { style: 'margin-top:26px;color:var(--dim);font-size:13px' }, 'Progress is saved in this browser, per course. ', h('a', { href: '#/verify' }, 'Self-check all labs'), '.')));
}
function viewCourse(id) {
  const all = allBlocks(), d = all.filter(b => isDone(b.id)).length, r = resumeFor(course);
  $app.append(h('div', { class: 'page', style: 'max-width:1100px' },
    h('div', { class: 'crumbs' }, h('a', { href: '#/' }, 'Welcome'), ' / ', course.title),
    h('h1', {}, course.title),
    h('div', { class: 'toolbar' }, h('a', { class: 'btn', href: r.href }, (r.started ? 'Continue: ' : 'Start: ') + r.label)),
    h('p', {}, 'Learn the whole QML language the freeCodeCamp way: ', h('b', {}, 'Theory → Lab → Practice test → Theory → Lab → Review'), '. Labs run a real (mini) QML engine in your browser and check your code with tests, offline. The course ends in a final project: your own Dynamic Island.'),
    h('div', { class: 'bar' }, h('i', { style: 'width:' + (100 * d / all.length) + '%' })),
    h('div', { class: 'mods' },
      course.modules.map((m, i) => {
        const dn = m.blocks.filter(b => isDone(b.id)).length;
        return h('div', { class: 'card' },
          h('h3', {}, (i + 1) + '. ' + m.title), h('p', {}, m.desc),
          h('div', { class: 'bar' }, h('i', { style: 'width:' + (100 * dn / m.blocks.length) + '%' })),
          h('div', { class: 'dim', style: 'font-size:13px;color:var(--dim);margin-bottom:10px' }, dn + ' of ' + m.blocks.length + ' blocks complete'),
          h('a', { class: 'btn sm', href: '#/m/' + m.id }, dn ? 'Continue' : 'Start'));
      }),
      (course.upcoming || []).map((u, i) => h('div', { class: 'card coming' }, h('h3', {}, (course.modules.length + i + 1) + '. ' + u.title), h('p', {}, u.desc), h('span', { class: 'state' }, 'coming next')))
    ),
    h('p', { style: 'margin-top:26px;color:var(--dim);font-size:13px' }, 'Progress is saved in this browser. ', h('a', { href: '#/verify' }, 'Self-check all labs'), ' (runs every reference solution through its tests).')));
}

// ------------------------------------------------------------------ module
function viewModule(id) {
  const m = course.modules.find(x => x.id === id);
  if (!m) return viewWelcome();
  $app.append(h('div', { class: 'page' },
    h('div', { class: 'crumbs' }, h('a', { href: '#/' }, 'Welcome'), ' / ', h('a', { href: '#/c/' + course.id }, course.title), ' / ', m.title),
    h('h1', {}, m.title), h('p', {}, m.desc),
    h('div', { class: 'bar' }, h('i', { style: 'width:' + (100 * m.blocks.filter(b => isDone(b.id)).length / m.blocks.length) + '%' })),
    h('ul', { class: 'blocks' }, m.blocks.map(b => h('li', { onclick: () => location.hash = '#/b/' + b.id },
      h('span', { class: 't' }, TYPE_LABEL[b.type]), h('span', { class: 'n' }, b.title, h('div', { class: 'd' }, b.desc || '')),
      h('span', { class: 'chk' + (isDone(b.id) ? ' on' : '') }, isDone(b.id) ? '✓' : ''))))));
}
function nextLink(m, b) {
  const i = m.blocks.indexOf(b), nx = m.blocks[i + 1];
  return nx ? h('a', { class: 'btn', href: '#/b/' + nx.id }, 'Next: ' + nx.title + ' →') : h('a', { class: 'btn', href: '#/m/' + m.id }, 'Back to module');
}
function viewBlock(id) {
  const [m, b] = blockById(id);
  if (!b) return viewWelcome();
  ({ theory: viewTheory, lab: viewLab, quiz: viewQuiz, review: viewReview })[b.type](m, b);
}
const head = (m, b) => h('div', {}, h('div', { class: 'crumbs' }, h('a', { href: '#/' }, 'Welcome'), ' / ', h('a', { href: '#/c/' + course.id }, course.title), ' / ', h('a', { href: '#/m/' + m.id }, m.title), ' / ', b.title), h('h1', {}, TYPE_LABEL[b.type] + ': ' + b.title));

// ------------------------------------------------------------------ question widget (theory + quiz)
function question(q, qid, onResult) {
  const name = 'q' + Math.random().toString(36).slice(2);
  const res = h('div', { class: 'res' });
  const opts = q.options.map((o, i) => h('label', { class: 'opt' }, h('input', { type: 'radio', name, value: i }), h('span', { html: o })));
  const box = h('div', { class: 'q' }, h('div', { html: '<b>' + q.text + '</b>' }), opts,
    h('button', { class: 'btn sm', onclick: () => {
      const sel = box.querySelector('input:checked');
      if (!sel) { res.className = 'res no'; res.textContent = 'Pick an answer first.'; return; }
      const ok = +sel.value === q.answer;
      res.className = 'res ' + (ok ? 'ok' : 'no');
      res.innerHTML = (ok ? 'Passed. ' : 'Not passed. ') + '<span class="why">' + (q.why || '') + '</span>';
      prog.q[qid] = ok; saveProg(); onResult && onResult(ok);
    } }, 'Check answer'), res);
  if (prog.q[qid]) { res.className = 'res ok'; res.innerHTML = 'Passed. <span class="why">' + (q.why || '') + '</span>'; }
  return box;
}

// ------------------------------------------------------------------ playground (editor + live preview)
function playground(files, opts = {}) {
  const names = Object.keys(files);
  let cur = names[0];
  const state = Object.assign({}, files);
  const preview = h('div', { class: 'pv' }), con = h('div', { class: 'con' });
  const rt = new window.QmlRuntime({ container: preview });
  let timer = 0;
  const show = () => {
    con.innerHTML = '';
    for (const e of rt.errors) con.append(h('div', { class: 'e' }, (e.file ? e.file + (e.line ? ':' + e.line : '') + ': ' : '') + e.message));
    for (const l of rt.logs) con.append(h('div', { class: 'l' }, 'qml: ' + l));
    if (!rt.errors.length && !rt.logs.length) con.append(h('div', { class: 'okm' }, 'No errors.'));
  };
  rt.onLog = () => show(); rt.onError = () => show();
  const run = () => { rt.load(state, state['main.qml'] !== undefined ? 'main.qml' : names[0]); rt.start(); show(); };
  const ed = createEditor(state[cur], v => { state[cur] = v; clearTimeout(timer); timer = setTimeout(run, 450); }, run);
  const tabs = h('div', { class: 'tabs' }, names.map(n => h('button', { class: n === cur ? 'on' : '', onclick: ev => {
    state[cur] = ed.value; cur = n; ed.value = state[n];
    tabs.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.textContent === n));
  } }, n)));
  const api = { state, rt, preview, con, ed, run, tabs, current: () => { state[cur] = ed.value; return Object.assign({}, state); },
    setFiles: f => { for (const k of Object.keys(state)) delete state[k]; Object.assign(state, f); cur = Object.keys(f)[0]; ed.value = state[cur]; tabs.querySelectorAll('button').forEach(b => b.classList.toggle('on', b.textContent === cur)); run(); } };
  setTimeout(run, 0);
  return api;
}

// ------------------------------------------------------------------ theory
function viewTheory(m, b) {
  const page = h('div', { class: 'page' }, head(m, b), b.intro ? h('p', { html: b.intro }) : null);
  const status = [];
  const refresh = () => {
    const ok = b.lessons.every((l, i) => !l.q || prog.q[b.id + ':' + i]);
    if (ok && !isDone(b.id)) { markDone(b.id); updateOverall(); }
    done.disabled = !ok; doneNote.textContent = ok ? 'All questions passed.' : 'Pass every question to finish this block.';
  };
  const done = h('a', { class: 'btn', href: '#', onclick: ev => { ev.preventDefault(); if (!done.disabled) location.hash = nextHash(m, b); } }, 'Continue →');
  const doneNote = h('span', { style: 'margin-left:12px;color:var(--dim)' });
  b.lessons.forEach((l, i) => {
    const st = h('span', { class: 'state' + (prog.q[b.id + ':' + i] ? ' ok' : '') }, l.q ? (prog.q[b.id + ':' + i] ? 'Passed' : 'Not Passed') : 'Read');
    const sec = h('section', { class: 'lesson' }, st, h('h2', {}, l.title), h('div', { html: l.html }));
    if (l.example) {
      const pg = playground(typeof l.example === 'string' ? { 'main.qml': l.example } : l.example);
      cleanups.push(() => pg.rt.dispose());
      sec.append(h('div', { class: 'ex' }, h('div', { class: 'exh' }, 'Try it: edit the code, the preview updates live'), h('div', { class: 'pg' }, pg.ed.el, h('div', { style: 'display:grid;grid-template-rows:2fr 1fr;min-height:0' }, pg.preview, pg.con))));
    }
    if (l.q) sec.append(question(l.q, b.id + ':' + i, ok => { st.className = 'state' + (ok ? ' ok' : ''); st.textContent = ok ? 'Passed' : 'Not Passed'; refresh(); }));
    page.append(sec);
  });
  page.append(h('div', { class: 'toolbar' }, done, doneNote));
  $app.append(page); refresh();
}
function nextHash(m, b) { const i = m.blocks.indexOf(b), nx = m.blocks[i + 1]; return nx ? '#/b/' + nx.id : '#/m/' + m.id; }

// ------------------------------------------------------------------ quiz
function viewQuiz(m, b) {
  const page = h('div', { class: 'page' }, head(m, b), h('p', {}, b.intro || 'Answer every question. You need at least 70% to pass.'));
  const picks = [];
  const result = h('div', { class: 'score' });
  b.questions.forEach((q, i) => {
    const name = 'qz' + i;
    page.append(h('div', { class: 'lesson' }, h('div', { html: '<b>' + (i + 1) + '. ' + q.text + '</b>' }),
      q.options.map((o, k) => h('label', { class: 'opt', style: 'display:block;margin:6px 0' }, h('input', { type: 'radio', name, value: k, onchange: () => { picks[i] = k; } }), ' ', h('span', { html: o }))),
      h('div', { class: 'res', id: 'qzr' + i })));
  });
  page.append(h('div', { class: 'toolbar' }, h('button', { class: 'btn', onclick: () => {
    let ok = 0;
    b.questions.forEach((q, i) => {
      const r = page.querySelector('#qzr' + i), good = picks[i] === q.answer; if (good) ok++;
      r.className = 'res ' + (good ? 'ok' : 'no'); r.innerHTML = (good ? 'Correct. ' : 'Not quite. ') + '<span class="why">' + (q.why || '') + '</span>';
    });
    const pct = Math.round(100 * ok / b.questions.length);
    result.textContent = ok + ' / ' + b.questions.length + ' (' + pct + '%) ' + (pct >= 70 ? '— passed!' : '— review the theory and try again.');
    if (pct >= 70) { markDone(b.id); updateOverall(); }
  } }, 'Submit answers'), nextLink(m, b)), result);
  $app.append(page);
}

// ------------------------------------------------------------------ review
function viewReview(m, b) {
  $app.append(h('div', { class: 'page' }, head(m, b), h('div', { class: 'lesson', html: b.html }),
    h('div', { class: 'toolbar' }, h('button', { class: 'btn', onclick: () => { markDone(b.id); updateOverall(); location.hash = '#/m/' + m.id; } }, 'Mark as reviewed'))));
}

// ------------------------------------------------------------------ test running
function runTests(lab, files, rt) {
  const results = [];
  const loaded = rt.load(files, 'main.qml');
  for (const test of lab.tests) {
    const r = { story: test.story, ok: false, why: '' };
    try {
      if (!loaded && !test.allowErrors) {
        const e = rt.errors[0]; r.why = 'QML error: ' + (e.file ? e.file + ':' : '') + (e.line ? e.line + ': ' : '') + e.message;
      } else {
        const t = makeKit(rt, files);
        test.run(t);
        r.ok = true;
      }
    } catch (e) {
      r.why = e instanceof Fail ? e.message : 'Test could not run: ' + e.message;
    }
    // each test starts from a fresh engine so tests cannot disturb each other
    results.push(r);
    if (!(loaded === false)) rt.load(files, 'main.qml');
  }
  return results;
}

// ------------------------------------------------------------------ lab
function viewLab(m, b) {
  const saved = prog.files[b.id];
  const start = saved || b.files;
  const pg = playground(JSON.parse(JSON.stringify(start)));
  cleanups.push(() => pg.rt.dispose());
  let saveT = 0;
  pg.ed.el.addEventListener('input', () => { clearTimeout(saveT); saveT = setTimeout(() => { prog.files[b.id] = pg.current(); saveProg(); }, 500); });
  const list = h('div', {});
  const msg = h('div', { style: 'margin:10px 0;font-weight:700' });
  const renderStories = res => {
    list.innerHTML = '';
    b.tests.forEach((t, i) => {
      const r = res && res[i];
      list.append(h('div', { class: 'story ' + (r ? (r.ok ? 'p' : 'f') : '') }, h('span', { class: 'm' }, r ? (r.ok ? '✓' : '✗') : (i + 1) + '.'), h('div', {}, h('span', { html: t.story }), r && !r.ok ? h('span', { class: 'why' }, r.why) : null)));
    });
  };
  const test = () => {
    const files = pg.current();
    const tmp = document.createElement('div'); document.body.append(tmp); tmp.style.cssText = 'position:absolute;left:-9999px;top:0';
    const rt = new window.QmlRuntime({ container: tmp });
    const res = runTests(b, files, rt); rt.dispose(); tmp.remove();
    renderStories(res);
    const pass = res.filter(r => r.ok).length;
    if (pass === res.length) { msg.style.color = 'var(--ok)'; msg.textContent = 'Congratulations, your code passes. Lab complete!'; markDone(b.id); updateOverall(); nextBtn.style.display = ''; }
    else { msg.style.color = 'var(--bad)'; msg.textContent = pass + ' of ' + res.length + ' tests pass. Keep going.'; }
    pg.run();
  };
  const nextBtn = nextLink(m, b); nextBtn.style.display = isDone(b.id) ? '' : 'none';
  const sol = h('details', { style: 'margin-top:14px;color:var(--dim)' }, h('summary', {}, 'Stuck? Show the reference solution'),
    h('div', {}, Object.entries(b.solution).map(([n, s]) => h('div', {}, h('div', { class: 'dim' }, n), h('pre', { style: 'background:#0a0a23;padding:10px;overflow:auto;font:13px var(--mono)' }, s))),
      h('button', { class: 'btn sm ghost', onclick: () => pg.setFiles(JSON.parse(JSON.stringify(b.solution))) }, 'Load solution into editor')));
  renderStories(null);
  const left = h('div', { class: 'left' }, h('div', { class: 'crumbs' }, h('a', { href: '#/m/' + m.id }, m.title), ' / Lab'), h('h2', { style: 'margin-top:0' }, b.title),
    h('div', { html: b.desc2 || '' }), h('h3', {}, 'User stories'), list,
    h('div', { class: 'toolbar' }, h('button', { class: 'btn', onclick: test }, 'Run the Tests (Ctrl+Enter runs the preview)'), h('button', { class: 'btn ghost', onclick: () => { if (confirm('Reset the code to the starting point?')) { delete prog.files[b.id]; saveProg(); pg.setFiles(JSON.parse(JSON.stringify(b.files))); renderStories(null); msg.textContent = ''; } } }, 'Reset')),
    msg, nextBtn, sol);
  const right = h('div', { class: 'right' }, h('div', { class: 'edwrap' }, pg.tabs, pg.ed.el),
    h('div', { class: 'lower' }, h('div', { style: 'display:grid;grid-template-rows:auto 1fr;min-height:0' }, h('div', { class: 'pvhead' }, 'Preview'), pg.preview), h('div', { style: 'display:grid;grid-template-rows:auto 1fr;min-height:0' }, h('div', { class: 'conhead' }, 'Console'), pg.con)));
  $app.append(h('div', { class: 'lab' }, left, right));
  $app.style.maxWidth = '1700px';
}

// ------------------------------------------------------------------ verify: every solution passes, every starter fails
function viewVerify() {
  const tbl = h('table', { class: 'vt' }, h('tr', {}, h('td', {}, 'Lab'), h('td', {}, 'Starter (should fail)'), h('td', {}, 'Solution (should pass)'), h('td', {}, 'Details')));
  $app.append(h('div', { class: 'page', style: 'max-width:1100px' }, h('h1', {}, 'Self-check'), tbl));
  const tmp = h('div', { style: 'position:absolute;left:-9999px;top:0' }); document.body.append(tmp);
  window.__verify = { rows: [] };
  for (const bl of everyBlock().filter(x => x.type === 'lab')) {
    const rt = new window.QmlRuntime({ container: tmp });
    const a = runTests(bl, bl.files, rt), s = runTests(bl, bl.solution, rt); rt.dispose();
    const aOk = a.some(r => !r.ok), sOk = s.every(r => r.ok);
    const bad = s.filter(r => !r.ok).map(r => r.story.replace(/<[^>]+>/g, '') + ' → ' + r.why).join(' | ');
    window.__verify.rows.push({ id: bl.id, starterFails: aOk, solutionPasses: sOk, bad });
    tbl.append(h('tr', {}, h('td', {}, bl.id + ' ' + bl.title), h('td', { class: aOk ? 'ok' : 'no' }, aOk ? 'fails ✓' : 'PASSES (bad)'), h('td', { class: sOk ? 'ok' : 'no' }, sOk ? 'passes ✓' : 'FAILS'), h('td', {}, bad)));
  }
  tmp.remove(); window.__verify.done = true;
}

route();
})();
