# Handoff

## Projects and facts
- NixOS 26.05 flake `~/Documents/MyNixOS`. Hosts: `desktop` (Ryzen 7 3700X, GTX 1060, 2 monitors), `laptop`, `surface`, `installer`. Terminal alacritty+zsh.
- dynisland: shell code in `modules/desktop/shell/dynisland/` (niri + Quickshell). Command `dynisland start|restart|stable|stop|dev|ipc ...|settings|launcher|server|log`.
- QMLCamp (offline course site, vanilla JS): `index.html`, `css/`, `js/{i18n,parser,runtime,testkit,editor,app}.js`, `content/m1..m8.js`, `content/i18n/*.js`, `tools/harness.html`. Routes: `#/` welcome, `#/c/<course>`, `#/m/<module>`, `#/b/<block>`, `#/verify` (every lab starter must fail, every solution must pass).
- Block pattern per module: Theory, Lab, Quiz, Theory, Lab, Review. Schema: `window.QMLCAMP.modules.push({id,title,desc,blocks:[...]})`.
  - theory `{id,type:'theory',title,desc,lessons:[{title,html,example,q:{text,options,answer,why}}]}`
  - lab `{id,type:'lab',title,desc,desc2,files:{'main.qml':...},solution:{...},tests:[{story,run:t=>{...}}]}`
  - quiz `{id,type:'quiz',title,desc,questions:[...]}`
  - review `{id,type:'review',title,desc,html}`
- Test kit `t`: find/has/all/count/click/hover/advance/eq/near/expect/noErrors/rgb/nodes/bindingOf/isBound/declares/behaviorMs/source (throw to fail).
- i18n: `QMLCAMP.tr[lang][id] = {title,desc,intro,desc2,html,lessons:[{title,html,q:{text,options,why}}],questions:[...],stories:[...]}`. Languages en, ja, es (es-ES), de. Never translate code, identifiers, test strings or engine errors. Array lengths and order equal English. Missing keys fall back to English.
- Rust: `rust-lib.js` API is `RustLib.runProgram`, `makeRustKit`, `highlightRust`, `fmtErr`. It depends on `window.RustCore` from `rust.js`, which was lost.
- Sandbox: `rg` may be missing (use grep). Python Playwright may not work on NixOS; use `playwright-driver.browsers` + `PLAYWRIGHT_BROWSERS_PATH` or `chromium --headless`.

## TODO (approved; do in order; mark [x]; ask before changing the list)
1. [ ] Decide the newest QMLCamp copy; merge translations (m1 to m8) and the JS course (`js1.js`) without losing either.
2. [ ] Rust: rebuild `rust.js` against `rust-lib.js` (lexer, parser, evaluator with ownership/borrow errors, traits, generics, `?`, iterators, closures, collections, `Rc/RefCell`, overflow panics); verify with sample programs (f1, f2, g1 to g3 style).
3. [ ] Rust course (modules, labs, quizzes) passing `#/verify`; translate welcome/UI strings if new keys were added.
4. [ ] Language switcher: finish untranslated block text (es, de, ja), one module per delivery.
5. [ ] Not requested yet (ask first): more courses, progress export/import.

## Current state
- QMLCamp: modules 1 to 8 done, 20 labs pass `#/verify`. Welcome page and language switcher done. i18n: infra + m1 to m7 translated in one copy; another copy also has m8 and `js1.js`. Newest copy not confirmed.
- Rust: `rust-lib.js` exists; `rust.js` lost; nothing rebuilt yet.
- dynisland: Server Mode applied (button untested end to end). Bar/dock visibility (Always/Auto-hide/Dodge) applied, not confirmed. Desktop debloat not applied: `sudo nixos-rebuild boot --flake .#desktop`, then after reboot stop stale `inir` units and `sudo nix-collect-garbage -d`.
- Tooling: OpenCode config, AGENTS.md and /handoff command written. Zen key not connected yet. v11 handoff was never seen; this state comes from v12 of the old kit.

## Where the conversation stopped
OpenCode + Zen setup finished on NixOS; nothing built yet. Next: the user attaches or points to the QMLCamp copies (and `rust-lib.js` for Rust), then start at TODO 1.

## Open questions
- Which QMLCamp copy is newest?
- `autoupgrade.nix` has a broken flake URL (advise `enable = false`).
- niri bind `sed` fix (`spawn "dynisland" "ipc"`).
- Lock cards/board confirmation.
- Should llama.cpp be desktop-only?
