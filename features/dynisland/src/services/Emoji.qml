// Emoji data + search + recent list for the emoji panel (UiState.openPanel("emoji")).
// Each entry: "<emoji> <keywords...>". TO ADD EMOJI: append to `all`.
pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root
    property var recent: []     // last used (kept until the shell restarts)

    readonly property var all: [
        "😀 grin smile happy", "😂 joy laugh lol", "🤣 rofl laugh", "😊 blush smile", "😍 love heart eyes", "😘 kiss", "😎 cool sunglasses",
        "🤔 think hmm", "😅 sweat nervous", "😉 wink", "🙂 slight smile", "🙃 upside down", "😴 sleep zzz", "😭 cry sob", "😢 sad tear",
        "😡 angry mad", "🥳 party celebrate", "🤯 mind blown", "😱 scream shock", "🥺 pleading", "😬 grimace", "🙄 eye roll", "😏 smirk",
        "🤗 hug", "🤝 handshake deal", "👍 thumbs up yes ok", "👎 thumbs down no", "👏 clap", "🙌 raised hands", "🙏 pray thanks please",
        "💪 muscle strong", "👋 wave hello bye", "✌️ peace victory", "🤞 fingers crossed luck", "👀 eyes look", "🧠 brain", "💀 skull dead",
        "👻 ghost", "🤖 robot bot", "👽 alien", "💩 poop", "🔥 fire hot lit", "✨ sparkles magic", "⭐ star", "🌟 glowing star", "💯 hundred perfect",
        "❤️ heart love red", "🧡 orange heart", "💛 yellow heart", "💚 green heart", "💙 blue heart", "💜 purple heart", "🖤 black heart", "💔 broken heart",
        "🎉 tada party", "🎂 cake birthday", "🎁 gift present", "🎮 game controller", "🎧 headphones music", "🎵 music note", "📷 camera photo", "🎬 movie clapper",
        "💻 laptop computer", "🖥️ desktop monitor", "⌨️ keyboard", "🖱️ mouse", "📱 phone mobile", "🔋 battery", "🔌 plug power", "💾 floppy save disk",
        "📁 folder", "📄 page file document", "📝 memo note write", "📌 pin", "📎 paperclip", "🔗 link chain", "🔒 lock", "🔓 unlock", "🔑 key",
        "⚙️ gear settings", "🔧 wrench tool", "🛠️ tools hammer wrench", "🐛 bug", "🐞 ladybug bug", "🚀 rocket launch", "⚡ zap lightning fast", "💡 idea bulb",
        "📊 chart bar stats", "📈 chart up growth", "📉 chart down", "🗑️ trash delete", "📦 package box", "🧪 test tube experiment", "🔍 search magnifier", "🕐 clock time",
        "⏰ alarm clock", "⌛ hourglass", "📅 calendar date", "📧 email mail", "💬 speech chat comment", "📢 loudspeaker announce", "🔔 bell notification", "🔕 bell off mute",
        "✅ check done yes", "❌ cross no x", "⚠️ warning", "❓ question", "❗ exclamation", "➕ plus add", "➖ minus", "➡️ arrow right", "⬅️ arrow left", "⬆️ arrow up", "⬇️ arrow down",
        "🔄 refresh cycle", "♻️ recycle", "🆗 ok", "🆕 new", "🐧 linux penguin tux", "🐍 python snake", "🦀 rust crab", "🐱 cat", "🐶 dog", "🦊 fox", "🐼 panda",
        "🦄 unicorn", "🐢 turtle slow", "🦋 butterfly", "🌱 seedling plant", "🌳 tree", "🌸 blossom flower", "🌹 rose", "🍀 clover luck", "🌙 moon night", "☀️ sun", "☁️ cloud",
        "🌧️ rain", "❄️ snow cold", "🌈 rainbow", "🌍 earth world globe", "🍕 pizza", "🍔 burger", "🍟 fries", "🍎 apple", "🍌 banana", "🍓 strawberry", "☕ coffee", "🍺 beer",
        "🍷 wine", "🥤 drink", "🍪 cookie", "🍫 chocolate", "🏠 house home", "🚗 car", "✈️ plane travel", "🏆 trophy win", "⚽ soccer football", "🏀 basketball", "🎯 target dart goal",
        "🧩 puzzle", "🎲 dice random", "♟️ chess", "🇪🇸 spain flag", "🇬🇧 uk flag", "🇺🇸 usa flag", "🏳️‍🌈 pride rainbow flag", "© copyright", "™ trademark", "→ arrow right", "← arrow left",
        "• bullet", "… ellipsis", "° degree", "± plus minus", "× times multiply", "÷ divide", "≠ not equal", "≈ approx", "∞ infinity", "π pi", "€ euro", "£ pound", "¥ yen"
    ]

    function glyph(e) { return e.slice(0, e.indexOf(" ")) }
    function search(q) {
        const s = q.trim().toLowerCase();
        if (s === "") {
            const r = recent.map(g => all.find(e => glyph(e) === g)).filter(e => e);
            return r.concat(all.filter(e => recent.indexOf(glyph(e)) < 0));
        }
        return all.filter(e => e.toLowerCase().indexOf(s) >= 0);
    }
    function copy(g) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + g + "' | wl-copy"]);
        recent = [g].concat(recent.filter(x => x !== g)).slice(0, Config.system.emojiRecent);
    }
}
