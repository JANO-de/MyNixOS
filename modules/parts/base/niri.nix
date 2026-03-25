{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.system}.myNiri;
    };
  };

  perSystem = { pkgs, config, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        input.keyboard.xkb.layout = "es";

        layout = {
          gaps = 5;
        };

        binds = {
          "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
          "Mod+Q".close-window = null;
          "Mod+S".spawn-sh = "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
          "Mod+WheelScrollDown".focus-column-left = null;
          "Mod+WheelScrollUp".focus-column-right = null;
          "Mod+Ctrl+WheelScrollDown".focus-workspace-down = null;
          "Mod+Ctrl+WheelScrollUp".focus-workspace-up = null;

          "Mod+1".focus-workspace = "w0";
          "Mod+2".focus-workspace = "w1";
          "Mod+3".focus-workspace = "w2";
          "Mod+4".focus-workspace = "w3";
          "Mod+5".focus-workspace = "w4";
          "Mod+6".focus-workspace = "w5";
          "Mod+7".focus-workspace = "w6";
          "Mod+8".focus-workspace = "w7";
          "Mod+9".focus-workspace = "w8";
          "Mod+0".focus-workspace = "w9";

          "Mod+Shift+1".move-column-to-workspace = "w0";
          "Mod+Shift+2".move-column-to-workspace = "w1";
          "Mod+Shift+3".move-column-to-workspace = "w2";
          "Mod+Shift+4".move-column-to-workspace = "w3";
          "Mod+Shift+5".move-column-to-workspace = "w4";
          "Mod+Shift+6".move-column-to-workspace = "w5";
          "Mod+Shift+7".move-column-to-workspace = "w6";
          "Mod+Shift+8".move-column-to-workspace = "w7";
          "Mod+Shift+9".move-column-to-workspace = "w8";
          "Mod+Shift+0".move-column-to-workspace = "w9";

          "Mod+Left".focus-column-left = null;
          "Mod+Right".focus-column-right = null;
          "Mod+Up".focus-window-up = null;
          "Mod+Down".focus-window-down = null;

          "Mod+F".maximize-column = null;
          "Mod+G".fullscreen-window = null;
          "Mod+Shift+F".toggle-window-floating = null;
          "Mod+C".center-column = null;

          "Mod+Ctrl+S".spawn-sh = ''${lib.getExe pkgs.grim} -l 0 - | ${pkgs.wl-clipboard}/bin/wl-copy'';

          "Mod+Shift+S".spawn-sh = lib.getExe (pkgs.writeShellApplication {
            name = "screenshot-edit";
            runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.swappy pkgs.wl-clipboard ];
            text = ''
              grim -g "$(slurp -w 0)" - | swappy -f -
            '';
          });
        };

        workspaces = let
          settings = {layout.gaps = 5;};
        in {
          "w0" = settings;
          "w1" = settings;
          "w2" = settings;
          "w3" = settings;
          "w4" = settings;
          "w5" = settings;
          "w6" = settings;
          "w7" = settings;
          "w8" = settings;
          "w9" = settings;
        };
      };
    };
  };
}

