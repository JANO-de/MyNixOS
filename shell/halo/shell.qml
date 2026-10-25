// Halo: iPadOS look + Android mechanics shell for Hyprland (Quickshell).
// Run for testing:  quickshell -p ~/halo
import Quickshell
import qs.components

ShellRoot {
    LockScreen {}

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property ShellScreen modelData

            Desktop { screen: scope.modelData }
            Island { screen: scope.modelData }
            HomeScreen { screen: scope.modelData }
            Dock { screen: scope.modelData }
            DockDrag { screen: scope.modelData; screenName: scope.modelData.name }
            SplitDivider { screen: scope.modelData }
            SplitStage { screen: scope.modelData; screenName: scope.modelData.name }
            AppMenu { screen: scope.modelData; screenName: scope.modelData.name }
            WindowsMenu { screen: scope.modelData; screenName: scope.modelData.name }
            Shade { screen: scope.modelData }
            Overview { screen: scope.modelData }
            HaloSettings { screen: scope.modelData }
            LibSearch { screen: scope.modelData }
            NoteEdit { screen: scope.modelData }
            TopEdge { screen: scope.modelData }
            BottomEdge { screen: scope.modelData }
            SideEdge { screen: scope.modelData; leftSide: true }
            SideEdge { screen: scope.modelData; leftSide: false }
            Banner { screen: scope.modelData }
            KbdHandle { screen: scope.modelData }
            KbdButton { screen: scope.modelData }
        }
    }
}
