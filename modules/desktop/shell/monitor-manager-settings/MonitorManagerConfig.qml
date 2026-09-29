// Monitor Manager as an iNiR settings page.
//
// Registered in the settings registry as "Monitor Manager". The UI body is the
// shared MonitorManagerPane; only the theming and the page chrome are local,
// so the page and the standalone window stay in sync.
//
// qs.* imports are what upstream settings pages use: `qs` is the shell root
// module, `qs.services` carries the Translation singleton, and
// `qs.modules.common` carries ContentPage plus Appearance. The qs import URIs
// reject hyphens, which is why the shared UI lives in a `monitorManager`
// module directory (see ../monitor-manager/qmldir) and is imported as a module
// rather than reached with a relative import: quickshell resolves neither
// parent-directory nor same-directory imports for files loaded from inside the
// shell. Keeping the page in its own directory also means the standalone
// window, which has no iNiR import path, never scans these imports.
//
// Note: config.d/15-outputs.kdl is the single owner of output settings (see the
// home-manager niri config), so everything here writes through the backend and
// niri validates + reloads on every change.
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.monitorManager

ContentPage {
    id: root
    settingsPageIndex: 29
    settingsPageName: Translation.tr("Monitor Manager")

    SettingsTaskNavigator {
        icon: "display_settings"
        title: Translation.tr("Monitor Manager")
        description: Translation.tr("Rearrange screens by dragging, change resolution, refresh rate and scale, and save the arrangements you switch between as named profiles.")
        summary: Translation.tr("Layout · Modes · Profiles")
        width: 0
    }

    // Pick up the shell palette so the page matches the surrounding UI.
    MonitorManagerTheme {
        id: pageTheme
        background: Appearance.colors.colLayer0Base
        surface: Appearance.colors.colLayer1Base
        fg: Appearance.colors.colOnLayer1
        subtext: Appearance.colors.colSubtext
        accent: Appearance.colors.colPrimary
        outline: Qt.alpha(Appearance.colors.colOnLayer1, 0.18)
        error: Appearance.colors.colError
    }

    MonitorManagerPane {
        id: pane
        Layout.fillWidth: true
        Layout.preferredHeight: 900
        theme: pageTheme
    }
}
