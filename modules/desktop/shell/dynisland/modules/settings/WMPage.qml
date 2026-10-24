import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Page {
    title: "WM"

    readonly property string detectedWm: {
        if (Quickshell.env("MANGO_INSTANCE_SIGNATURE")) return "MangoWM";
        if (Quickshell.env("NIRI_SOCKET")) return "niri";
        return "unknown";
    }

    Text {
        text: "Detected compositor: " + detectedWm
        color: Theme.surfaceFg
        font.pixelSize: 15
        font.weight: Font.DemiBold
        topPadding: 8
        bottomPadding: 8
    }

    SettingRow { label: "Auto-detect compositor";
        Toggle { checked: Config.wm.autoDetect; onToggled: Config.wm.autoDetect = !Config.wm.autoDetect } }

    SettingRow { label: "Active WM"; hint: "This page writes the config for the compositor dynisland is running under"
        Text { text: detectedWm; color: Theme.primary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }

    SettingRow { label: "Monitor rotation"; hint: "Mango: 0=normal, 1=90° CCW, 3=270° CCW"
        SSlider { from: 0; to: 3; stepSize: 1; value: Config.wm.rotation; onMoved: v => Config.wm.rotation = Math.round(v) } }

    SettingRow { label: "Apply rotation to 1920x1080 output";
        Toggle { checked: Config.wm.applyRotation; onToggled: Config.wm.applyRotation = !Config.wm.applyRotation } }

    SettingRow { label: "Monitor match"; hint: "Mango requires a name/make/model/serial match before width/height/rr"
        Field { implicitWidth: 300; text: Config.wm.monitorMatch; onAccepted: t => Config.wm.monitorMatch = t } }

    SettingRow { label: "Border width";
        SSlider { from: 1; to: 12; stepSize: 1; value: Config.wm.borderPx; onMoved: v => Config.wm.borderPx = Math.round(v) } }
    SettingRow { label: "Inner gap";
        SSlider { from: 0; to: 32; stepSize: 1; value: Config.wm.gapInnerHorizontal; onMoved: v => Config.wm.gapInnerHorizontal = Math.round(v) } }
    SettingRow { label: "Outer gap";
        SSlider { from: 0; to: 40; stepSize: 1; value: Config.wm.gapOuterHorizontal; onMoved: v => Config.wm.gapOuterHorizontal = Math.round(v) } }

    SettingRow { label: "Corner radius";
        SSlider { from: 0; to: 24; stepSize: 1; value: Config.wm.borderRadius; onMoved: v => Config.wm.borderRadius = Math.round(v) } }

    Text { text: "Current config target"; color: Theme.surfaceFgDim; font.pixelSize: 12; topPadding: 10; bottomPadding: 4 }
    SettingRow { label: "Write Mango config"; hint: "Saves the live values to ~/.config/mango/config.conf and reloads mango"
        Row {
            spacing: 8
            PillButton {
                label: "Apply to Mango"; icon: "save"
                onClicked: Quickshell.execDetached(["bash", "-lc",
                    "mkdir -p ~/.config/mango && cat > ~/.config/mango/config.conf <<EOF\n" +
                    "border_px = " + Config.wm.borderPx + "\n" +
                    "gap_inner_horizontal = " + Config.wm.gapInnerHorizontal + "\n" +
                    "gap_inner_vertical = " + Config.wm.gapInnerVertical + "\n" +
                    "gap_outer_horizontal = " + Config.wm.gapOuterHorizontal + "\n" +
                    "gap_outer_vertical = " + Config.wm.gapOuterVertical + "\n" +
                    "border_radius = " + Config.wm.borderRadius + "\n" +
                    "monitor_rule = name:" + Config.wm.monitorMatch + ",width:1920,height:1080,refresh:60,rr:" + Config.wm.rotation + "\n" +
                    "EOF\n" +
                    "mmsg reload_config 2>/dev/null || true\n"])
            }
            PillButton {
                label: "Open WM config"; icon: "code"
                onClicked: Quickshell.execDetached(["bash", "-lc", "xdg-open ~/.config/mango/config.conf"]) }
        }
    }
}
