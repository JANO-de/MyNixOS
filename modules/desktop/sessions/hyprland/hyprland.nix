# Hyprland session (Lua config, Hyprland >= 0.55), launched through UWSM so
# graphical-session.target (and with it the dynisland user service) comes up.
# Config template: ./hyprland.lua.
#
# Uses the Hyprland FLAKE package (plugins must match its exact version), so the
# Cachix cache is configured here, ALWAYS on. Do not override the flake's nixpkgs.
{ config, lib, pkgs, inputs, theme, ... }:

let
  cfg = config.modules.desktop;
  sys = pkgs.stdenv.hostPlatform.system;
  hypr = inputs.hyprland.packages.${sys};
  hyprNixpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${sys};
  # Override with modules.desktop.drmDevices (the desktop PC has only the NVIDIA card: /dev/dri/dgpu).
  # Setting it also hides simpledrm (card0, the EFI framebuffer) from Aquamarine.
  drmDevices =
    if cfg.drmDevices != null then cfg.drmDevices
    else if config.hardware.nvidia.enable or false
    then "/dev/dri/igpu:/dev/dri/dgpu"
    else "/dev/dri/igpu";

  rgba = key: "rgba(${lib.removePrefix "#" (theme.color key)}ff)";

  screenshot = pkgs.writeShellScript "screenshot" ''
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    f="$dir/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
    g="$(${pkgs.slurp}/bin/slurp)" && [ -n "$g" ] \
      && ${pkgs.grim}/bin/grim -g "$g" "$f" \
      && ${pkgs.wl-clipboard}/bin/wl-copy < "$f"
  '';

  safeSharePicker = pkgs.writeShellScriptBin "hyprland-share-picker-safe" ''
    out="$(${hypr.xdg-desktop-portal-hyprland}/bin/hyprland-share-picker "$@" 2>/dev/null)"
    printf '%s\\n' "$out"
    exit 0
  '';

  # same shell binds as mango.nix / niri.nix
  shellBinds = lib.optionalString (cfg.shell == "dynisland") (
    lib.concatMapStringsSep "\n"
      (b: ''hl.bind("${b.key}", hl.dsp.exec_cmd("dynisland ipc ${b.ipc}"))'')
      [
        { key = "SUPER + space"; ipc = "launcher toggle"; }
        { key = "ALT + space"; ipc = "spotlight toggle"; }
        { key = "SUPER + SHIFT + L"; ipc = "lock lock"; }
        { key = "SUPER + Q"; ipc = "quick toggle"; }
        { key = "SUPER + V"; ipc = "tools clipboard"; }
        { key = "SUPER + CTRL + E"; ipc = "tools emoji"; }
        { key = "SUPER + SHIFT + C"; ipc = "tools color"; }
        { key = "SUPER + A"; ipc = "ai toggle"; }
        { key = "SUPER + comma"; ipc = "settings toggle"; }
        { key = "SUPER + I"; ipc = "island toggle"; }
      ]
  );

  sessionExtras =
    if cfg.hyprlandTouch.enable then
      ''dofile("/etc/hypr/hyprland-touch.lua")
dofile("/etc/hypr/hyprland-mode.lua")''
    else
      "";

  content =
    lib.replaceStrings
      [ "@ACCENT@" "@SURFACE@" "@POLKIT@" "@SCREENSHOT@" "@WPCTL@" "@SHELL_BINDS@" "@SESSION_EXTRAS@" "@DRM_DEVICES@" ]
      [
        (rgba "accent")
        (rgba "surface")
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${screenshot}"
        "${pkgs.wireplumber}/bin/wpctl"
        shellBinds
        sessionExtras
        drmDevices
      ]
      (builtins.readFile ./hyprland.lua);
in
{
  options.modules.desktop.drmDevices = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/dev/dri/dgpu";
    description = "Colon-separated DRM devices Hyprland (Aquamarine) may use. null = igpu (+ dgpu when NVIDIA is enabled).";
  };

  config = lib.mkMerge [
    # The cache must be active BEFORE the flake package is built, so this is not
    # gated on the session. First build: pass the same values on the CLI (see plan).
    {
      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    }

    (lib.mkIf (cfg.session == "hyprland") {
      programs.hyprland = {
        enable = true;
        withUWSM = true; # session entry: "hyprland-uwsm"
        package = hypr.hyprland;
        portalPackage = hypr.xdg-desktop-portal-hyprland;
      };

      # Applies to every shell (ii does not set it in its own Hyprland config).
      environment.sessionVariables.AQ_DRM_DEVICES = drmDevices;

      # The flake is built against its own nixpkgs: use that Mesa so the GL/GBM
      # libs match (Hyprland wiki, Nix page).
      #hardware.graphics.package = hyprNixpkgs.mesa;

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file picker
      services.gnome.gnome-keyring.enable = true;
      environment.systemPackages = with pkgs; [ polkit_gnome wl-clip-persist safeSharePicker ];

      home-manager.users.jano.home.activation.xdphConf = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.config/hypr"
        cat > "$HOME/.config/hypr/xdph.conf" <<'EOF'
screencopy {
    custom_picker_binary = ${safeSharePicker}/bin/hyprland-share-picker-safe
}
EOF
      '';

      home-manager.users.jano.home.activation.hyprlandLua = lib.mkIf (cfg.shell != "ii") (inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.config/hypr"
        if [ -L "$HOME/.config/hypr/hyprland.lua" ] || [ ! -e "$HOME/.config/hypr/hyprland.lua" ]; then
          run rm -f "$HOME/.config/hypr/hyprland.lua"
          run cp ${pkgs.writeText "hyprland.lua" content} "$HOME/.config/hypr/hyprland.lua"
          run chmod u+w "$HOME/.config/hypr/hyprland.lua"
        fi
      '');
    })
  ];
}
