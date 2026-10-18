// AI chat settings (services/AI.qml, modules/ai/AIChat.qml). Key is stored in
// ~/.config/dynisland/config.json in plain text.
import QtQuick
import qs.config
import qs.services
import qs.components

Page {
    title: "AI"
    SettingRow { label: "Anthropic API key"; hint: "console.anthropic.com -> API Keys. Stored locally, plain text."
        Field { implicitWidth: 320; text: Config.ai.apiKey; onAccepted: t => Config.ai.apiKey = t } }
    SettingRow { label: "Model"
        Field { implicitWidth: 240; text: Config.ai.model; onAccepted: t => Config.ai.model = t } }
    SettingRow { label: "System prompt"; hint: "Optional. Sent with every conversation."
        Field { implicitWidth: 320; text: Config.ai.systemPrompt; onAccepted: t => Config.ai.systemPrompt = t } }
    Text { text: "Open with IPC: qs -c dynisland ipc call ai toggle (bind a key in niri)."
           color: "#88ffffff"; font.pixelSize: 12; width: parent.width; wrapMode: Text.Wrap }
}
