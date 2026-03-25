{ inputs, ... }: {
  # This block runs for every system (x86_64-linux, etc.)
  perSystem = { pkgs, lib, self', ... }:
    let
      myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        settings = {
          spawn-at-startup = [(lib.getExe self'.packages.myNoctalia)];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          layout.gaps = 5;

          input = {
            keyboard = {
              xkb = {
                layout = "es";
                variant = "nodeadkeys"; # This removes the dead keys for accents/quotes
              };
            };
          };

          # --- Keys Configuration ---
          binds = {
            # Basics
            "Mod+Shift+Slash".show-hotkey-overlay = null;
            "Mod+Shift+E".quit = null;
            "Mod+Q".close-window = null;

            # Navigation
            "Mod+Left".focus-column-left = null;
            "Mod+Right".focus-column-right = null;
            "Mod+Ctrl+Left".move-column-left = null;
            "Mod+Ctrl+Right".move-column-right = null;

            # Workspaces
            "Mod+Page_Down".focus-workspace-down = null;
            "Mod+Page_Up".focus-workspace-up = null;
            "Mod+Ctrl+Page_Down".move-column-to-workspace-down = null;
            "Mod+Ctrl+Page_Up".move-column-to-workspace-up = null;

            # Layout & Windows
            "Mod+R".switch-preset-column-width = null;
            "Mod+F".maximize-column = null;
            "Mod+BracketLeft".consume-or-expel-window-left = null;
            "Mod+BracketRight".consume-or-expel-window-right = null;
            # Use simple toggle for floating
            "Mod+V".toggle-window-floating = null;

            # REMOVED: toggle-column-tabbed and show-overview (they don't exist in your version)
            # Replacing Mod+0 with a safe alternative for now
            "Mod+0".focus-workspace-down = null;

            # Apps
            "Print".spawn-sh = lib.getExe pkgs.grim; # Screenshot
            "Mod+T".spawn-sh = lib.getExe pkgs.foot; # Terminal
            "Mod+D".spawn-sh = lib.getExe pkgs.fuzzel; # Launcher
            "Mod+I".spawn-sh = lib.getExe pkgs.yazi; # Files
            "Mod+Alt+L".spawn-sh = "swaylock"; # Lock
            "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          };
        };
      };
    in {
      packages.my-niri = myNiri;
    };
}