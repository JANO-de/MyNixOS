// AI settings (services/AI.qml = the harness, modules/ai/AIChat.qml = the panel).
// Quick options live here and in config.json. Providers, custom API tools and MCP servers
// live in ~/.config/dynisland/ai.json (see docs/AI.md).
import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "AI"

    // ---- status
    SettingRow {
        label: "Active: " + (AI.provider ? (AI.provider.name || AI.provider.id) : "no provider") + " · " + Config.ai.model
        hint: AI.cfgError !== "" ? AI.cfgError
              : (AI.modelInfo ? "context " + AI.fmtTok(AI.modelInfo.context) + " · tools: " + AI.modelInfo.toolMode + " · thinking: " + AI.modelInfo.thinking
                                + (AI.modelInfo.local ? " · local" : "") : "Add a provider in ai.json")
        PillButton { implicitHeight: 34; label: "Reload ai.json"; icon: "refresh"; onClicked: { AI.reloadCfg(); AI.fetchModels() } }
    }
    SettingRow { label: "Provider"; hint: "Providers come from ai.json. Switch inside the chat with /provider."
        Chips { model: AI.providers.map(p => ({ label: p.name || p.id, value: p.id })); current: Config.ai.provider; onPicked: v => AI.setProvider(v) } }
    SettingRow { label: "Model"; hint: "Any model id the provider serves. /model in the chat lists them."
        Field { implicitWidth: 260; text: Config.ai.model; onAccepted: t => { if (t.trim()) Config.ai.model = t.trim() } } }

    // ---- behaviour
    SettingRow { label: "Thinking"; hint: "Claude: native extended thinking. Other models: asked to reason in <think> tags first."
        Chips { model: [{ label: "Off", value: "off" }, { label: "Low", value: "low" }, { label: "Medium", value: "medium" }, { label: "High", value: "high" }]
                current: Config.ai.thinking; onPicked: v => Config.ai.thinking = v } }
    SettingRow { label: "Show reasoning in the chat"
        Toggle { checked: Config.ai.showThinking; onToggled: Config.ai.showThinking = !Config.ai.showThinking } }
    SettingRow { label: "Tool approval"; hint: "Ask = confirm file edits and commands. Edits = confirm commands only. Auto = never ask (be careful)."
        Chips { model: [{ label: "Ask", value: "ask" }, { label: "Edits ok", value: "edits" }, { label: "Auto", value: "auto" }]
                current: Config.ai.approve; onPicked: v => Config.ai.approve = v } }
    SettingRow { label: "Working directory"; hint: "Where tools run and relative paths resolve. Empty = home. Also /cd in the chat."
        Field { implicitWidth: 260; text: Config.ai.cwd; placeholder: "~"; onAccepted: t => Config.ai.cwd = t.trim() } }
    SettingRow { label: "Max tool rounds per message"; hint: "Safety stop for runaway loops."
        Field { implicitWidth: 80; text: String(Config.ai.maxTurns); onAccepted: t => { const n = parseInt(t); if (n > 0) Config.ai.maxTurns = n } } }
    SettingRow { label: "Reopen the last chat on start"
        Toggle { checked: Config.ai.resumeLast; onToggled: Config.ai.resumeLast = !Config.ai.resumeLast } }

    // ---- prompt + key
    SettingRow { label: "Extra instructions"; hint: "Added to the built-in prompt for every model. Longer standing notes: ~/.config/dynisland/AI.md (or CLAUDE.md in the working directory)."
        Field { implicitWidth: 320; text: Config.ai.systemPrompt; onAccepted: t => Config.ai.systemPrompt = t } }
    SettingRow { label: "Anthropic API key (quick)"; hint: "console.anthropic.com -> API Keys. Stored in config.json in plain text. Safer: apiKeyCmd in ai.json (pass, sops, ...)."
        Field { implicitWidth: 320; text: Config.ai.apiKey; onAccepted: t => Config.ai.apiKey = t } }

    Text { text: "Open the chat: qs -c dynisland ipc call ai toggle  (bind it in niri). Send from a script: ipc call ai ask \"text\". Slash commands: /help."
           color: Theme.surfaceFgDim; font.pixelSize: 12; width: parent.width; wrapMode: Text.WordWrap; topPadding: 8 }
}
