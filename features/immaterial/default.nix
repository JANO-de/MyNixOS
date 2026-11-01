# immaterial-impulse shell module (Quickshell on Hyprland).
# Active when modules.desktop.shell = "immaterial".
# Upstream (https://github.com/XephyLon/immaterial-impulse) manages the QML tree,
# matugen config and seeded user config via its home-manager module. Hyprland
# config is seeded from the flake input (upstream does not manage ~/.config/hypr).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.modules.desktop;
  dotsEnable = config.modules.desktop.dotfiles.enable or false;
  dotsDir = config.modules.desktop.dotfiles.dir or "";
  hyprDir = if dotsEnable then "${dotsDir}/hypr" else "$HOME/.config/hypr";
  hmDag = inputs.home-manager.lib.hm.dag;
  imm = inputs.immaterial-impulse;
  sys = pkgs.stdenv.hostPlatform.system;

  immPython = pkgs.python3.withPackages (ps: [
    ps.pygobject3
    ps.click
    ps.loguru
    ps.tqdm
    ps.pillow
    ps.materialyoucolor
    ps.material-color-utilities
    ps.opencv4
    ps.numpy
    ps.dbus-python
    ps.evdev
    ps.psutil
    ps.requests
    ps.scipy
    ps.onnxruntime
    ps.websockets
    ps.pyyaml
    ps.fonttools
    ps.google-api-python-client
  ]);
  immVenv = pkgs.runCommand "immaterial-venv" { } ''
    mkdir -p $out/bin
    ln -s ${immPython}/bin/python3 $out/bin/python
    ln -s ${immPython}/bin/python3 $out/bin/python3
    printf '%s\n' '# dummy activate' > $out/bin/activate
  '';
in
{
  options.modules.desktop.immaterial.enable =
    lib.mkEnableOption "immaterial-impulse shell on Hyprland";

  config = lib.mkIf (cfg.shell == "immaterial") {
    environment.systemPackages = with pkgs; [
      imm.packages.${sys}.immaterial-impulse
      imm.packages.${sys}.quickshell-wrapped
      matugen
      hyprland
      hyprsunset
      wl-clipboard
      cliphist
      libnotify
      grim
      slurp
      wf-recorder
      brightnessctl
      playerctl
      xdg-utils
      adwaita-icon-theme
      pavucontrol
      localsend-cli
      gdk-pixbuf
      librsvg
      bc
      glib
      imagemagick
      fuzzel
      hypridle
      hyprlock
      hyprpicker
      translate-shell
      wlogout
      libqalculate
      cava
      pavucontrol
      wireplumber
      pipewire
      ddcutil
      geoclue2
      networkmanager
      wl-clipboard
      slurp
      brightnessctl
      playerctl
      cliphist
      upscayl
      pulseaudio
      bluez
      blueman
      glib
      gtk3
      gjs
      ffmpeg
      yt-dlp
      git
      file
      fontconfig
      procps
      psmisc
      util-linux
      xdg-utils
      uv
    ];

    home-manager.users.jano = {
      imports = [ imm.homeManagerModules.default ];

      programs.immaterial-impulse = {
        enable = true;
        package = imm.packages.${sys}.immaterial-impulse;
        quickshell.package = imm.packages.${sys}.quickshell-wrapped;
        seedConfig = true;
      };

      home.activation.immaterialHyprConfig = hmDag.entryAfter [ "writeBoundary" ] ''
        hd="${hyprDir}"
        run mkdir -p "$hd"
        if [ ! -e "$hd/hyprland.lua" ]; then
          run cp -r ${imm}/dots/.config/hypr/. "$hd/"
          run chmod -R u+w "$hd"
        fi
        # Ensure the shell launches with the ABI-matching wrapped qs (not PATH's).
        if [ -f "$hd/hyprland/execs.lua" ]; then
          run sed -i 's#QSG_RENDER_LOOP=threaded qs -c#QSG_RENDER_LOOP=threaded /run/current-system/sw/bin/qs -c#g; s#qs -c \$qsConfig ipc#/run/current-system/sw/bin/qs -c $qsConfig ipc#g' "$hd/hyprland/execs.lua"
        fi
        # Clamp shadow render_power to the compositor's maximum.
        if [ -f "$hd/hyprland/general.lua" ]; then
          run sed -i 's/render_power = 10,/render_power = 4,/' "$hd/hyprland/general.lua"
        fi
      '';

      home.activation.immaterialVenv = hmDag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.local/state/quickshell"
        if [ ! -e "$HOME/.local/state/quickshell/.venv" ]; then
          run ln -s ${immVenv} "$HOME/.local/state/quickshell/.venv"
        fi
      '';
    };
  };
}
