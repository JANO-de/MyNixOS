// Halo: iPadOS look + Android mechanics shell for Hyprland (Quickshell).
// Run for testing:  quickshell -p ~/halo
import Quickshell
import qs.components

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData

            Island { screen: scope.modelData }
            HomeScreen { screen: scope.modelData }
            Dock { screen: scope.modelData }
            Shade { screen: scope.modelData }
        }
    }
}
