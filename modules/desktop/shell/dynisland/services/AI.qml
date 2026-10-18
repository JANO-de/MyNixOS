// =============================================================================
//  AI — the agent harness behind the chat panel (modules/ai/AIChat.qml).
//
//  What it does
//    * talks to Anthropic (Messages API) or ANY OpenAI-compatible server (Ollama, LM Studio,
//      llama.cpp, vLLM, OpenRouter, OpenAI, Groq ...) and streams the reply token by token
//    * agent loop: the model can call tools (bash, read/write/edit files, web, HTTP, todo list,
//      your own API tools from ai.json), you approve them, results go back, repeat
//    * thinking (Anthropic native, <think> tags for other models), sessions on disk,
//      token / cost / context / rate-limit tracking, /compact, retries
//    * every model gets the same system prompt (aiharness.js) so they all behave alike
//
//  Config:   Settings > AI (quick options)  +  ~/.config/dynisland/ai.json (providers, tools, MCP)
//  Docs:     docs/AI.md
//  Pure logic lives in aiharness.js (unit-testable); this file is the Quickshell glue.
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "aiharness.js" as H

Singleton {
    id: root

    // ======================================================================= config
    readonly property string dataDir: Config.home + "/.local/share/dynisland/ai"
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string workDir: H.expandHome(Config.ai.cwd || "~", Config.home)
    property var cfg: H.defaultConfig()          // ~/.config/dynisland/ai.json
    property string cfgError: ""
    property bool dirReady: false

    readonly property var providers: cfg.providers || []
    readonly property var provider: {
        const list = providers;
        for (let i = 0; i < list.length; i++) if (list[i].id === Config.ai.provider) return list[i];
        return list.length ? list[0] : null;
    }
    readonly property var modelInfo: provider ? H.resolveModel(provider, Config.ai.model) : null
    readonly property var modelList: {            // configured + fetched, unique
        const out = [];
        if (!provider) return out;
        const add = id => { if (id && out.indexOf(id) < 0) out.push(id) };
        H.modelIds(provider).forEach(add);
        (remoteModels[provider.id] || []).forEach(add);
        return out;
    }

    function loadCfg(text) {
        try {
            const j = JSON.parse(text);
            if (!Array.isArray(j.providers)) j.providers = [];
            cfg = j; cfgError = "";
        } catch (e) { cfgError = "ai.json is not valid JSON: " + e }
    }
    FileView {
        id: cfgFile
        path: Config.ready ? Config.dir + "/ai.json" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadCfg(text())
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {      // first run: write the template
                root.cfg = H.defaultConfig();
                cfgFile.setText(JSON.stringify(H.defaultConfig(), null, 2));
            } else root.cfgError = "Cannot read ai.json";
        }
    }
    function reloadCfg() { cfgFile.reload() }

    // secrets reach curl through the environment, never through the command line
    function keyEnv(p) {
        let key = p.apiKey || "";
        const cmd = p.apiKeyCmd || "";
        if (!key && !cmd && p.kind === "anthropic" && Config.ai.apiKey) key = Config.ai.apiKey;   // Settings > AI field
        return { AI_KEY: key, AI_KEYCMD: cmd };
    }
    function hasKey(p) { const k = keyEnv(p); return !!(k.AI_KEY || k.AI_KEYCMD) }

    // ======================================================================= state
    property var sessions: []                     // [{id,title,updated,model,provider,cost}], newest first
    property string sid: ""
    property string title: ""
    property double created: 0
    property var messages: []                     // see aiharness.js for the format
    property var todos: []                        // [{content,status}]
    readonly property var rows: H.displayRows(messages)

    property var liveBlocks: []                   // the reply being streamed
    property bool busy: false
    property string phase: ""                     // "" | wait | stream | tools | compact
    property string error: ""
    property string info: ""                      // transient notice (commands, warnings)
    property var pending: null                    // { use, tool } waiting for your approval
    property string runningTool: ""
    property var allowed: []                      // tools you chose "always allow" for (this run)
    property string picker: ""                    // "" | model | provider  (UI overlay)
    property bool sidebar: false

    property var usage: ({ "in": 0, out: 0, cr: 0, cw: 0 })   // session totals
    property real cost: 0
    property bool costKnown: false
    property int ctxUsed: 0                       // tokens in the context after the last reply
    readonly property int ctxMax: modelInfo ? modelInfo.context : 0
    readonly property real ctxFrac: ctxMax > 0 ? Math.min(1, ctxUsed / ctxMax) : 0
    property var rate: []                         // [{label, remaining, limit, reset}]
    property int httpStatus: 0
    property string lastSystem: ""
    property var remoteModels: ({})               // providerId -> [ids]
    property bool xmlMode: false

    // internals
    property var stream: null
    property string curMode: "chat"               // chat | compact
    property bool chatActive: false
    property bool stopped: false
    property bool dirty: false
    property double reqStart: 0
    property int turns: 0
    property int retries: 0
    property var toolDefs: []
    property var toolQueue: []
    property var toolResults: []
    property var curUse: null
    property bool started: false
    readonly property string bodyPath: runDir + "/dynisland-ai-body.json"
    readonly property string hdrPath: runDir + "/dynisland-ai-hdr.txt"

    // ======================================================================= low level processes
    Process { running: true; command: ["mkdir", "-p", root.dataDir]; onExited: root.dirReady = true }

    FileView { id: bodyFile; blockWrites: true; printErrors: false }       // request body for curl
    FileView { id: hdrFile; blockLoading: true; printErrors: false }       // response headers (rate limits)
    FileView { id: tf; blockWrites: true; printErrors: false }             // write_file / edit_file
    FileView { id: memFile; blockLoading: true; printErrors: false }       // memory files
    FileView { id: sessR; blockLoading: true; printErrors: false }         // read a session
    FileView { id: sessW; blockWrites: true; printErrors: false }          // write a session
    FileView {
        id: idxFile
        path: root.dirReady ? root.dataDir + "/index.json" : ""
        blockWrites: true; printErrors: false
        onLoaded: root.onIndex(text())
        onLoadFailed: err => root.onIndex("[]")
    }

    // the streaming chat call
    Process {
        id: chat
        stdout: SplitParser { onRead: line => root.onLine(line) }
        onExited: (code, status) => root.onChatExit(code)
    }
    // tool runner (one tool at a time)
    Process {
        id: shell
        property var cb: null
        stdout: StdioCollector { onStreamFinished: { const f = shell.cb; shell.cb = null; if (f) f(text) } }
    }
    // background calls (model list)
    Process {
        id: bg
        property string provId: ""
        stdout: StdioCollector { onStreamFinished: root.onModels(bg.provId, text) }
    }
    Process { id: clip }
    Process { id: rm }

    function sh(script, args, env, cb) {
        shell.cb = cb;
        shell.environment = env || ({});
        shell.command = ["bash", "-c", H.RUNNER, "bash", script].concat(args || []);
        shell.running = true;
    }

    Timer {
        interval: 60; repeat: true; running: root.phase === "wait" || root.phase === "stream"
        onTriggered: if (root.dirty) { root.dirty = false; root.refreshLive() }
    }
    Timer { id: saveT; interval: 600; onTriggered: root.saveNow() }
    Timer { id: retryT; onTriggered: root.run(root.curMode) }

    // ======================================================================= helpers
    function copy(text) {
        clip.environment = { AI_CLIP: String(text) };
        clip.command = ["bash", "-c", "printf %s \"$AI_CLIP\" | wl-copy"];
        clip.running = true;
    }
    function envInfo() {
        return { cwd: workDir, date: Qt.formatDateTime(new Date(), "dddd d MMMM yyyy, HH:mm"), os: "NixOS (Linux), niri (Wayland)", shell: "bash" };
    }
    function readMemory() {
        let out = "";
        const files = [cfg.memoryFile, workDir + "/CLAUDE.md", workDir + "/AGENTS.md"];
        for (let i = 0; i < files.length; i++) {
            if (!files[i]) continue;
            const p = H.expandHome(files[i], Config.home);
            memFile.path = p;
            try { memFile.reload(); const t = memFile.text(); if (t && t.trim()) out += (out ? "\n\n" : "") + "(" + p + ")\n" + t.trim() }
            catch (e) { /* file missing: fine */ }
        }
        return out;
    }
    function fail(msg) { error = msg; finishTurn() }
    function finishTurn() {
        busy = false; phase = ""; runningTool = ""; curUse = null; liveBlocks = []; stream = null; curMode = "chat";
        saveSoon();
    }

    // ======================================================================= send / run
    function send(text) {
        let t = (text || "").trim();
        if (!t) return;
        if (t.indexOf("//") === 0) t = t.slice(1);
        else if (/^\/[a-z]+(\s|$)/i.test(t)) { command(t); return }
        if (busy) return;
        ensureSession(t);
        messages = messages.concat([H.userMsg(t)]);
        error = ""; info = ""; turns = 0; retries = 0; stopped = false; busy = true;
        run("chat");
    }

    function run(mode) {
        curMode = mode;
        const p = provider;
        if (!p) { fail("No provider configured. Edit " + Config.dir + "/ai.json"); return }
        if (!Config.ai.model) { fail("No model selected. Use /model"); return }
        if ((p.kind === "anthropic" || p.requireKey) && !hasKey(p)) { fail("No API key for " + (p.name || p.id) + ". Settings > AI, or set apiKey / apiKeyCmd in ai.json."); return }
        const mdl = H.resolveModel(p, Config.ai.model);
        const xml = mdl.toolMode === "xml";
        const tools = mode === "chat" ? H.allTools(cfg.tools, cfg.disabledTools) : [];
        toolDefs = tools; xmlMode = xml;
        const thinkTags = mode === "chat" && p.kind !== "anthropic" && Config.ai.thinking !== "off" && mdl.reasoning === "tags";
        const system = H.buildSystem({
            env: envInfo(), user: Config.ai.systemPrompt, memory: mode === "chat" ? readMemory() : "",
            provider: p.name || p.id, model: mdl.id,
            xmlTools: xml && tools.length ? tools : null, thinkTags: thinkTags
        });
        lastSystem = system;
        let msgs = messages;
        if (mode === "compact") msgs = [H.userMsg(H.COMPACT_PROMPT + "\n\n---\n" + H.transcript(messages))];
        const req = H.buildRequest({
            provider: p, model: mdl, system: system, messages: msgs, tools: tools,
            level: mode === "chat" ? Config.ai.thinking : "off",
            mcp: p.mcp || cfg.mcp || [], cache: true, xml: xml
        });
        bodyFile.path = bodyPath;
        bodyFile.setText(JSON.stringify(req.body));
        stream = H.newStream(p);
        liveBlocks = []; dirty = false;
        reqStart = Date.now(); phase = mode === "compact" ? "compact" : "wait";
        chat.environment = keyEnv(p);
        chat.command = ["bash", "-c", H.SH_CHAT, "bash", H.endpoint(p, "chat"), bodyPath, hdrPath, H.authHeaderFormat(p)].concat(H.baseHeaders(p, req.beta));
        chatActive = true;
        chat.running = true;
    }

    function onLine(line) { if (stream && stream.feed(line)) dirty = true }
    function refreshLive() {
        if (!stream) return;
        liveBlocks = H.liveDisplay(stream.blocks.filter(Boolean), xmlMode);
        if (phase === "wait" && liveBlocks.length) phase = "stream";
    }

    function onChatExit(code) {
        chatActive = false;
        if (!stream) return;
        const wasStopped = stopped;
        let hdr = "";
        hdrFile.path = hdrPath;
        try { hdrFile.reload(); hdr = hdrFile.text() } catch (e) { hdr = "" }
        rate = H.parseRate(hdr);
        httpStatus = H.statusOfHeaders(hdr);
        const res = stream.finish({ xml: xmlMode });
        stream = null; liveBlocks = [];

        if (curMode === "compact") { finishCompact(res); return }

        let blocks = res.blocks;
        if (wasStopped) blocks = blocks.filter(b => b.type !== "tool_use");
        if (!blocks.length) {
            if (wasStopped) { finishTurn(); return }
            if ([429, 503, 529].indexOf(httpStatus) >= 0 && retries < 2) {         // overloaded / rate limited: wait and retry
                retries++;
                const wait = Math.min(30, Math.max(3, H.retryAfter(hdr) || (4 * retries)));
                info = "Provider busy (HTTP " + httpStatus + "). Retrying in " + wait + " s (" + retries + "/2)…";
                phase = "wait"; retryT.interval = wait * 1000; retryT.restart();
                return;
            }
            let msg = res.error || (code !== 0 ? "Request failed (curl exit " + code + ")" : "Empty response from the model");
            if (httpStatus >= 400 && msg.indexOf("HTTP") !== 0) msg = "HTTP " + httpStatus + ": " + msg;
            fail(msg);
            return;
        }
        const msg = { role: "assistant", blocks: blocks, usage: res.usage, model: res.model || Config.ai.model, ms: Date.now() - reqStart, ts: Date.now(), stop: res.stop };
        const mdl = modelInfo;
        const c = H.costOf(res.usage, mdl ? mdl.pricing : null);
        if (c !== null) { msg.cost = c; cost += c; costKnown = true }
        usage = H.addUsage(usage, res.usage);
        messages = messages.concat([msg]);
        ctxUsed = res.estimated ? H.estMessagesTokens(messages) : H.ctxTokens(res.usage) + (res.usage.out || 0);
        if (res.error) error = res.error;
        else if (res.stop === "max_tokens") info = "The reply was cut off (max tokens reached). Say \"continue\" to go on.";
        const uses = wasStopped ? [] : H.toolUses(blocks);
        if (uses.length) startTools(uses); else finishTurn();
    }

    // ======================================================================= tools
    function startTools(uses) {
        turns++;
        toolQueue = uses.slice(); toolResults = [];
        if (turns > Config.ai.maxTurns) {
            toolQueue.forEach(u => addResult(u, "Not run: the tool-round limit (" + Config.ai.maxTurns + ") was reached.", true));
            toolQueue = [];
            commitResults();
            error = "Stopped after " + Config.ai.maxTurns + " tool rounds. Say \"continue\" to go on.";
            finishTurn();
            return;
        }
        phase = "tools";
        nextTool();
    }

    function toolByName(name) {
        for (let i = 0; i < toolDefs.length; i++) if (toolDefs[i].name === name) return toolDefs[i];
        return null;
    }
    function addResult(u, out, isErr) {
        let c = typeof out === "string" ? out : JSON.stringify(out);
        if (c.trim() === "") c = "(no output)";
        toolResults = toolResults.concat([{ type: "tool_result", tool_use_id: u.id, content: H.clip(c, 40000), is_error: !!isErr }]);
    }
    function commitResults() {
        if (!toolResults.length) return;
        messages = messages.concat([{ role: "user", blocks: toolResults, ts: Date.now() }]);
        toolResults = [];
    }

    function nextTool() {
        if (stopped) return;
        if (!toolQueue.length) { commitResults(); phase = "wait"; run("chat"); return }
        const u = toolQueue[0];
        toolQueue = toolQueue.slice(1);
        const tool = toolByName(u.name);
        if (!tool) { addResult(u, "Unknown tool \"" + u.name + "\". Available: " + toolDefs.map(t => t.name).join(", "), true); nextTool(); return }
        if (H.needsApproval(tool, Config.ai.approve, allowed.concat(cfg.allow || []))) { pending = { use: u, tool: tool }; return }
        exec(u, tool);
    }
    function approve(always) {
        const p = pending; if (!p) return;
        pending = null;
        if (always && allowed.indexOf(p.tool.name) < 0) allowed = allowed.concat([p.tool.name]);
        exec(p.use, p.tool);
    }
    function deny() {
        const p = pending; if (!p) return;
        pending = null;
        addResult(p.use, "The user denied this tool call. Do not retry it unchanged; ask what they want instead.", true);
        nextTool();
    }

    function exec(u, tool) {
        curUse = u; runningTool = u.id;
        const input = u.input || ({});
        const wd = workDir;
        const done = (out, isErr) => {
            if (stopped) return;
            curUse = null; runningTool = "";
            addResult(u, out, isErr);
            nextTool();
        };
        const str = v => v === undefined || v === null ? "" : String(v);

        switch (u.name) {
        case "bash": {
            const t = Math.max(1, Math.min(600, parseInt(input.timeout) || 60));
            sh(H.SH_BASH, [wd, String(t), str(input.command)], {}, text => {
                const r = H.splitExit(text);
                let out = H.clip(r.out, 30000);
                if (r.code === 124) out += "\n(timed out after " + t + " s)";
                if (r.code !== 0) out += "\n[exit code " + r.code + "]";
                done(out, r.code !== 0);
            });
            break;
        }
        case "read_file": {
            const p = H.resolvePath(input.path, wd, Config.home);
            const off = Math.max(1, parseInt(input.offset) || 1);
            const lim = Math.max(1, Math.min(5000, parseInt(input.limit) || 2000));
            sh(H.SH_READ, [p, String(off), String(off + lim - 1)], {}, text => { const r = H.splitExit(text); done(H.clip(r.out, 60000), r.code !== 0) });
            break;
        }
        case "list_dir": {
            const p = H.resolvePath(input.path || ".", wd, Config.home);
            sh(H.SH_LIST, [p], {}, text => { const r = H.splitExit(text); done(r.out, r.code !== 0) });
            break;
        }
        case "write_file": {
            const p = H.resolvePath(input.path, wd, Config.home);
            const content = str(input.content);
            sh(H.SH_MKPARENT, [p], {}, () => {
                tf.path = p;
                tf.setText(content);
                sh('[ -f "$1" ] && wc -c < "$1" || echo MISSING', [p], {}, t2 => {
                    const r = H.splitExit(t2), n = r.out.trim();
                    if (n === "MISSING" || (parseInt(n) === 0 && content.length > 0)) done("Write failed: " + p + " was not created.", true);
                    else done("Wrote " + n + " bytes (" + content.split("\n").length + " lines) to " + p, false);
                });
            });
            break;
        }
        case "edit_file": {
            const p = H.resolvePath(input.path, wd, Config.home);
            sh('[ -f "$1" ] || { echo "No such file: $1"; exit 1; }; cat -- "$1"', [p], {}, text => {
                const r = H.splitExit(text);
                if (r.code !== 0) { done(r.out, true); return }
                const e = H.applyEdit(r.out, str(input.old_string), str(input.new_string), !!input.replace_all);
                if (!e.ok) { done(e.error, true); return }
                tf.path = p;
                tf.setText(e.text);
                done("Edited " + p + " (" + e.count + " replacement" + (e.count > 1 ? "s" : "") + ")", false);
            });
            break;
        }
        case "web_fetch": {
            const max = Math.max(500, Math.min(100000, parseInt(input.max_chars) || 20000));
            sh(H.SH_FETCH, [str(input.url), String(max)], {}, text => { const r = H.splitExit(text); done(r.out, r.code !== 0) });
            break;
        }
        case "http_request": {
            const hdrs = Object.keys(input.headers || {}).map(k => k + ": " + input.headers[k]);
            const hasBody = input.body !== undefined && input.body !== null && input.body !== "";
            const env = { AI_KEY: "", AI_KEYCMD: "", AI_HASBODY: hasBody ? "1" : "0", AI_BODY: hasBody ? str(input.body) : "" };
            sh(H.SH_HTTP, [str(input.method || "GET").toUpperCase(), str(input.url), ""].concat(hdrs), env, text => httpDone(text, 20000, done));
            break;
        }
        case "todo_write": {
            todos = (input.todos || []).map(t => ({ content: str(t.content), status: str(t.status || "pending") }));
            done("Task list updated (" + todos.length + " items).", false);
            break;
        }
        default: {
            const defs = cfg.tools || [];
            let def = null;
            for (let i = 0; i < defs.length; i++) if (defs[i].name === u.name) def = defs[i];
            if (!def) { done("Unknown tool " + u.name, true); break }
            const call = H.buildHttpCall(def, input);
            const a = def.auth || {};
            let fmt = "";
            if (a.key || a.keyCmd) {
                if (a.format) fmt = (a.header ? a.header : "Authorization") + ": " + a.format;                    // e.g. header "Authorization", format "Token %s"
                else if (a.header && a.header.toLowerCase() !== "authorization") fmt = a.header + ": %s";        // e.g. header "X-Api-Key"
                else fmt = "Authorization: Bearer %s";
            }
            const hdrs = Object.keys(call.headers).map(k => k + ": " + call.headers[k]);
            const env = { AI_KEY: a.key || "", AI_KEYCMD: a.keyCmd || "", AI_HASBODY: call.body !== null ? "1" : "0", AI_BODY: call.body !== null ? call.body : "" };
            sh(H.SH_HTTP, [call.method, call.url, fmt].concat(hdrs), env, text => httpDone(text, def.maxChars || 20000, done));
        }
        }
    }
    function httpDone(text, max, done) {
        const r = H.splitExit(text);
        const h = H.splitHttp(r.out);
        const body = H.clip(h.body, max);
        done((h.status ? "HTTP " + h.status + "\n" : "") + body, r.code !== 0 || h.status >= 400 || h.status === 0);
    }

    // ======================================================================= stop / retry / compact
    function stop() {
        if (!busy) return;
        stopped = true;
        retryT.stop();
        if (pending) { addResult(pending.use, "Denied (stopped by the user).", true); pending = null }
        if (chatActive) { chat.running = false; return }           // onChatExit keeps the partial reply
        if (shell.running) shell.running = false;
        if (curUse) { addResult(curUse, "Interrupted: stopped by the user.", true); curUse = null }
        toolQueue.forEach(u => addResult(u, "Interrupted: stopped by the user.", true));
        toolQueue = [];
        commitResults();
        finishTurn();
    }

    function retry() {
        if (busy || !messages.length) return;
        const m = messages.slice();
        while (m.length && m[m.length - 1].role === "assistant") m.pop();
        if (!m.length) return;
        messages = m; error = ""; info = ""; turns = 0; retries = 0; stopped = false; busy = true;
        run("chat");
    }

    function compact() {
        if (busy) return;
        if (messages.length < 2) { info = "Nothing to compact yet."; return }
        error = ""; info = ""; stopped = false; busy = true;
        run("compact");
    }
    function finishCompact(res) {
        const text = H.textOf(res.blocks);
        if (stopped || res.error || !text.trim()) { if (!stopped) error = res.error || "Compaction failed."; finishTurn(); return }
        const before = ctxUsed;
        usage = H.addUsage(usage, res.usage);
        const c = H.costOf(res.usage, modelInfo ? modelInfo.pricing : null);
        if (c !== null) { cost += c; costKnown = true }
        messages = [
            H.userMsg("Summary of our conversation so far (compacted to save context):\n\n" + text),
            { role: "assistant", blocks: [{ type: "text", text: "Understood. I have the summary and will continue from there." }], ts: Date.now() }
        ];
        ctxUsed = H.estMessagesTokens(messages);
        info = "Compacted: about " + H.fmtTok(before) + " → " + H.fmtTok(ctxUsed) + " tokens of context.";
        finishTurn();
    }

    // ======================================================================= sessions
    function ensureSession(firstText) {
        if (sid) return;
        sid = H.newId(); created = Date.now(); title = H.titleFrom(firstText);
    }
    function saveSoon() { if (sid) saveT.restart() }
    function saveNow() {
        if (!sid || !dirReady || !messages.length) return;
        const upd = Date.now();
        const s = { id: sid, title: title, created: created, updated: upd, provider: Config.ai.provider, model: Config.ai.model,
                    cwd: Config.ai.cwd, messages: messages, todos: todos, usage: usage, cost: cost };
        sessW.path = dataDir + "/s-" + sid + ".json";
        sessW.setText(JSON.stringify(s));
        const idx = sessions.filter(x => x.id !== sid);
        idx.unshift({ id: sid, title: title, updated: upd, model: Config.ai.model, provider: Config.ai.provider, cost: cost });
        sessions = idx;
        idxFile.setText(JSON.stringify(idx));
    }
    function onIndex(text) {
        let idx = [];
        try { idx = JSON.parse(text) } catch (e) { idx = [] }
        sessions = Array.isArray(idx) ? idx : [];
        if (!started) {
            started = true;
            if (Config.ai.resumeLast && sessions.length && !sid && !messages.length) openSession(sessions[0].id);
        }
        fetchModels();
    }
    function resetState() {
        sid = ""; title = ""; created = 0; messages = []; todos = []; usage = { "in": 0, out: 0, cr: 0, cw: 0 };
        cost = 0; costKnown = false; ctxUsed = 0; error = ""; info = ""; pending = null; allowed = []; liveBlocks = [];
    }
    function newSession() {
        if (busy) return;
        saveNow();
        resetState();
    }
    function clearSession() {
        if (busy) return;
        const id = sid;
        resetState();
        if (id) deleteSession(id);
    }
    function openSession(id) {
        if (busy || id === sid) return;
        saveNow();
        sessR.path = dataDir + "/s-" + id + ".json";
        let j;
        try { sessR.reload(); j = JSON.parse(sessR.text()) } catch (e) { error = "Could not open that session: " + e; return }
        resetState();
        sid = j.id; title = j.title || "Chat"; created = j.created || Date.now();
        messages = H.repairHistory(j.messages || []);
        todos = j.todos || []; usage = j.usage || usage; cost = j.cost || 0; costKnown = cost > 0;
        if (j.provider) Config.ai.provider = j.provider;
        if (j.model) Config.ai.model = j.model;
        if (j.cwd !== undefined) Config.ai.cwd = j.cwd;
        ctxUsed = H.estMessagesTokens(messages);
    }
    function deleteSession(id) {
        rm.command = ["rm", "-f", dataDir + "/s-" + id + ".json"];
        rm.running = true;
        const idx = sessions.filter(x => x.id !== id);
        sessions = idx;
        idxFile.setText(JSON.stringify(idx));
        if (id === sid) resetState();
    }

    // ======================================================================= models / providers
    function fetchModels() {
        const p = provider;
        if (!p || bg.running) return;
        bg.provId = p.id;
        bg.environment = keyEnv(p);
        bg.command = ["bash", "-c", H.RUNNER, "bash", H.SH_HTTP, "GET", H.endpoint(p, "models"), H.authHeaderFormat(p)].concat(H.baseHeaders(p, []));
        bg.running = true;
    }
    function onModels(provId, text) {
        const r = H.splitHttp(H.splitExit(text).out);
        const ids = H.parseModelList(r.body);
        if (!ids.length) return;
        const m = Object.assign({}, remoteModels);
        m[provId] = ids;
        remoteModels = m;
    }
    function setModel(id) {
        Config.ai.model = id; picker = "";
        const mi = H.resolveModel(provider, id);
        info = "Model: " + id + (mi.thinking === "off" && Config.ai.thinking !== "off" && provider.kind === "anthropic" ? " (this model has no extended thinking)" : "");
    }
    function setProvider(id) {
        let p = null;
        for (let i = 0; i < providers.length; i++) if (providers[i].id === id) p = providers[i];
        if (!p) { info = "No provider \"" + id + "\" in ai.json. Have: " + providers.map(x => x.id).join(", "); return }
        Config.ai.provider = id; picker = "";
        const ids = H.modelIds(p);
        if (ids.length && ids.indexOf(Config.ai.model) < 0) Config.ai.model = ids[0];
        allowed = [];
        fetchModels();
        info = "Provider: " + (p.name || p.id) + " · model " + Config.ai.model;
    }

    // ======================================================================= slash commands
    readonly property string helpText: [
        "/new  new chat          /clear  delete this chat      /sessions  show/hide chat list",
        "/model [id]  pick model  /provider [id]  pick provider  /think off|low|medium|high",
        "/approve ask|edits|auto  /compact  summarize to free context   /retry  /stop",
        "/cd <dir>  working dir   /system  show system prompt   /tools   /usage   /reload  /help",
        "Start a message with // to send a literal leading slash."
    ].join("\n")

    function command(line) {
        const sp = line.indexOf(" ");
        const cmd = (sp < 0 ? line : line.slice(0, sp)).toLowerCase();
        const arg = sp < 0 ? "" : line.slice(sp + 1).trim();
        error = "";
        switch (cmd) {
        case "/new": newSession(); break;
        case "/clear": clearSession(); break;
        case "/sessions": sidebar = !sidebar; break;
        case "/compact": compact(); break;
        case "/retry": retry(); break;
        case "/stop": stop(); break;
        case "/model": if (arg) setModel(arg); else picker = picker === "model" ? "" : "model"; break;
        case "/provider": if (arg) setProvider(arg); else picker = picker === "provider" ? "" : "provider"; break;
        case "/think":
            if (["off", "low", "medium", "high"].indexOf(arg) >= 0) {
                Config.ai.thinking = arg;
                info = "Thinking: " + arg + (arg !== "off" && modelInfo && modelInfo.kind === "anthropic" && modelInfo.thinking === "off" ? " (ignored: this Claude model has no extended thinking)" : "");
            } else info = "Thinking is " + Config.ai.thinking + ". Usage: /think off|low|medium|high";
            break;
        case "/approve":
            if (["ask", "edits", "auto"].indexOf(arg) >= 0) { Config.ai.approve = arg; info = "Tool approval: " + arg }
            else info = "Approval is \"" + Config.ai.approve + "\". Usage: /approve ask|edits|auto  (ask = confirm edits and commands, edits = confirm commands only, auto = never ask)";
            break;
        case "/cd": if (arg) Config.ai.cwd = arg; info = "Working directory: " + workDir; break;
        case "/system": info = lastSystem ? lastSystem : "No request has been sent yet."; break;
        case "/tools": info = H.allTools(cfg.tools, cfg.disabledTools).map(t => t.name + " (" + t.perm + ")").join(", "); break;
        case "/usage":
            info = "Session: " + H.fmtTok(usage["in"]) + " in, " + H.fmtTok(usage.out) + " out, " + H.fmtTok(usage.cr) + " cached read"
                 + (costKnown ? ", " + H.fmtCost(cost) : "") + ". Context " + H.fmtTok(ctxUsed) + " / " + H.fmtTok(ctxMax) + ".";
            break;
        case "/reload": reloadCfg(); fetchModels(); info = "Reloaded ai.json"; break;
        case "/help": info = helpText; break;
        default: info = "Unknown command " + cmd + ". Type /help. (Start with // to send a literal slash.)";
        }
    }

    // ======================================================================= text for the UI
    function fmtTok(n) { return H.fmtTok(n) }
    function fmtCost(c) { return H.fmtCost(c) }
    function rowInfo(r) {                         // under each reply: time, tokens, speed, cost
        const parts = [];
        if (r.ms) parts.push((r.ms / 1000).toFixed(1) + " s");
        if (r.usage) {
            parts.push(H.fmtTok(r.usage.out) + " out");
            if (r.ms > 500 && r.usage.out) parts.push(Math.round(r.usage.out / (r.ms / 1000)) + " tok/s");
            if (r.usage.cr) parts.push(H.fmtTok(r.usage.cr) + " cached");
        }
        if (r.cost !== null && r.cost !== undefined) parts.push(H.fmtCost(r.cost));
        return parts.join(" · ");
    }
    function limitsLine() {                       // provider rate limits from the last response headers
        return rate.filter(x => x.limit !== undefined || x.remaining !== undefined)
                   .map(x => x.label + " " + (x.remaining !== undefined ? H.fmtTok(x.remaining) : "?") + (x.limit ? "/" + H.fmtTok(x.limit) : "")).join("  ");
    }
    function usageLine() {
        let s = "in " + H.fmtTok(usage["in"] + usage.cr + usage.cw) + " · out " + H.fmtTok(usage.out);
        if (usage.cr) s += " · cached " + H.fmtTok(usage.cr);
        if (costKnown) s += " · " + H.fmtCost(cost);
        else if (modelInfo && modelInfo.local) s += " · local";
        return s;
    }
    readonly property var commandList: [
        { c: "/new", d: "new chat" }, { c: "/sessions", d: "chat list" }, { c: "/model", d: "pick model" },
        { c: "/provider", d: "pick provider" }, { c: "/think", d: "off | low | medium | high" },
        { c: "/approve", d: "ask | edits | auto" }, { c: "/compact", d: "free up context" },
        { c: "/retry", d: "run last message again" }, { c: "/cd", d: "working directory" },
        { c: "/system", d: "show system prompt" }, { c: "/tools", d: "list tools" }, { c: "/usage", d: "tokens and cost" },
        { c: "/reload", d: "reload ai.json" }, { c: "/clear", d: "delete this chat" }, { c: "/help", d: "all commands" }
    ]

    // The old API kept for the island / IPC callers
    function clear() { clearSession() }
}
