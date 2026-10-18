// =============================================================================
//  AI — minimal Anthropic Messages API client.
//    AI.busy          a request is in flight
//    AI.messages       [{role:"user"|"assistant", text}], newest last
//    AI.send(text)     appends the user message, calls the API, appends the reply
//    AI.clear()        wipes history (not persisted across restarts)
//  Needs Config.ai.apiKey set in Settings > AI. Uses curl (no extra deps).
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property bool busy: false
    property string error: ""
    property var messages: []   // [{role, text}]

    function clear() { messages = []; error = "" }

    function send(text) {
        const t = (text || "").trim();
        if (!t || busy) return;
        if (!Config.ai.apiKey) { error = "Set an API key in Settings > AI first."; return }
        messages = messages.concat([{ role: "user", text: t }]);
        error = ""; busy = true;

        const body = {
            model: Config.ai.model,
            max_tokens: 1024,
            system: Config.ai.systemPrompt || undefined,
            messages: messages.map(m => ({ role: m.role, content: m.text }))
        };
        proc.buffer = "";
        proc.command = ["curl", "-s", "-m", "60", "https://api.anthropic.com/v1/messages",
            "-H", "x-api-key: " + Config.ai.apiKey,
            "-H", "anthropic-version: 2023-06-01",
            "-H", "content-type: application/json",
            "-d", JSON.stringify(body)];
        proc.running = true;
    }

    Process {
        id: proc
        property string buffer: ""
        stdout: StdioCollector { onStreamFinished: proc.handle(text) }
        function handle(out) {
            root.busy = false;
            let j;
            try { j = JSON.parse(out) } catch (e) { root.error = "Bad response from API"; return }
            if (j.error) { root.error = j.error.message || "API error"; return }
            const txt = (j.content || []).filter(b => b.type === "text").map(b => b.text).join("");
            if (txt) root.messages = root.messages.concat([{ role: "assistant", text: txt }]);
            else root.error = "Empty response";
        }
    }
}
