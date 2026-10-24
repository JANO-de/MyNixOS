# MangoWM, the default session on desktop and laptop. Configured declaratively
# through the mango Home Manager module (wayland.windowManager.mango.settings);
# the result is ~/.config/mango/config.conf. Docs: https://mangowm.github.io/docs/
#
#   bind=MODS,KEY,dispatcher,args   one list item per bind under `bind`
#   bindl                           same, but also works on the lock screen
#   tag_rule                        per-tag layout (scroller = niri-style columns)
{ config, lib, pkgs, inputs, theme, ... }:

let
  cfg = config.modules.desktop;
  mod = "SUPER";
  surfaceTouchDisabled = config.networking.hostName == "surface";

  # theme color -> mango's 0xRRGGBBAA
  hex = key: "0x${lib.removePrefix "#" (theme.color key)}ff";

  # Small scripts, so binds stay comma-free (mango splits bind params on commas).
  brightness = dir: pkgs.writeShellScript "brightness-${dir}" ''
    ${pkgs.brightnessctl}/bin/brightnessctl -q set 5%${if dir == "up" then "+" else "-"}
    v=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4 | tr -d '%')
    dynisland ipc osd show brightness "$(${pkgs.gawk}/bin/awk -v v="$v" 'BEGIN { print v / 100 }')" || true
  '';
  screenshot = pkgs.writeShellScript "screenshot" ''
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    f="$dir/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
    case "$1" in
      screen) ${pkgs.grim}/bin/grim "$f" ;;
      *) g="$(${pkgs.slurp}/bin/slurp)" && [ -n "$g" ] && ${pkgs.grim}/bin/grim -g "$g" "$f" ;;
    esac && ${pkgs.wl-clipboard}/bin/wl-copy < "$f"
  '';
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";

  dirs = { Left = "left"; Right = "right"; Up = "up"; Down = "down"; };
  arrows = mods: dispatcher: lib.mapAttrsToList (k: d: "${mods},${k},${dispatcher},${d}") dirs;
  tags = lib.range 1 9;

  shellBinds = lib.optionals (cfg.shell == "dynisland") [
    "${mod},space,spawn,dynisland ipc launcher toggle"
    "ALT,space,spawn,dynisland ipc spotlight toggle" # the old niri bind had a stray `call`
    "${mod}+SHIFT,l,spawn,dynisland ipc lock lock"
    "${mod},q,spawn,dynisland ipc quick toggle"
    "${mod},v,spawn,dynisland ipc tools clipboard"
    "${mod}+CTRL,e,spawn,dynisland ipc tools emoji"
    "${mod}+SHIFT,c,spawn,dynisland ipc tools color"
    "${mod},a,spawn,dynisland ipc ai toggle"
    "${mod},comma,spawn,dynisland ipc settings toggle"
    "${mod},i,spawn,dynisland ipc island toggle"
  ];
in
{
  options.modules.desktop.mango.monitorRules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "name:^HDMI-A-1$,width:3840,height:2160,refresh:60,x:0,y:0,scale:1.5" ];
    description = ''
      mango monitor_rule lines (one per output), e.g. for a fractional scale or a
      fixed layout. Names and modes: `mmsg get all-monitors` / `wlr-randr`.
      Never use negative positions (XWayland click bug).
    '';
  };

  config = lib.mkIf (cfg.session == "mango") {
    # ---- system side: session entry + Wayland deps + portals -----------------
    programs.mango.enable = true;

    # Screen sharing (wlr), file picker (gtk), secrets (keyring). The wlr portal
    # has no chooser of its own and falls back to slurp, which is installed.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
      config.mango = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
    services.gnome.gnome-keyring.enable = true;
    environment.systemPackages = with pkgs; [ polkit_gnome wl-clip-persist ];

    # ---- user side: ~/.config/mango/config.conf -------------------------------
    home-manager.sharedModules = [ inputs.mango.hmModules.mango ];
    home-manager.users.jano.wayland.windowManager.mango = {
      enable = true;

      # mango-session.target imports these into the systemd/D-Bus user
      # environment before it starts graphical-session.target. The defaults plus
      # MANGO_INSTANCE_SIGNATURE, which the shell's `mmsg` calls need.
      systemd.variables = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "NIXOS_OZONE_WL"
        "XCURSOR_THEME"
        "XCURSOR_SIZE"
        "MANGO_INSTANCE_SIGNATURE"
      ];

      # The shell (dynisland) autostarts as a systemd user service; the clipboard
      # history watchers are started by the shell itself (Config.system.clipWatch).
      autostart_sh = ''
        ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
        wl-clip-persist --clipboard regular --reconnect-tries 0 &
      '';

      settings = {
        # ---- input (es / nodeadkeys, as on niri) ----
        xkb_rules_layout = "es";
        xkb_rules_variant = "nodeadkeys";
        xkb_rules_options = "compose:rctrl";
        numlock_on = 1;
        repeat_rate = 25;
        repeat_delay = 600;
        tap_to_click = 1;
        trackpad_natural_scrolling = 1;
        trackpad_disable_while_typing = 1;
        mouse_accel_profile = 2; # adaptive
        touch_enable = if surfaceTouchDisabled then 0 else 1;
        touch_enable_mouse_emulation = if surfaceTouchDisabled then 0 else 1;

        # ---- look: theme.nix (catppuccin mocha / mauve) ----
        border_px = 4;
        gap_inner_horizontal = 10;
        gap_inner_vertical = 10;
        gap_outer_horizontal = 20;
        gap_outer_vertical = 20;
        root_color = hex "bgDeep";
        border_color = hex "surface";
        focus_color = hex "accent";
        urgent_color = hex "error";
        border_radius = 12;
        animations = 1;
        cursor_theme = "Adwaita";
        cursor_size = 24;

        env = [
          "ELECTRON_OZONE_PLATFORM_HINT,wayland"
          "QT_IMAGEIO_MAXALLOC,0"
        ];

        # scroller = niri-style columns on every tag
        tag_rule = map (i: "id:${toString i},layout_name:scroller") tags;

        bind =
          [
            "${mod},Return,spawn,alacritty"
            "${mod},e,spawn,alacritty -e yazi"
            "${mod},b,spawn,zen"
            "${mod},w,killclient"
            "${mod}+SHIFT,e,quit"
            "CTRL+ALT,Delete,quit"
            "${mod}+SHIFT,r,reload_config"

            "${mod},f,togglemaximizescreen"
            "${mod}+SHIFT,f,togglefullscreen"
            "${mod}+CTRL,v,togglefloating"
            "${mod},c,centerwin"
            "${mod},r,switch_proportion_preset"
            "${mod}+SHIFT,t,switch_layout"
            "${mod},Tab,toggleoverview"
            "${mod},minus,setmfact,-0.05"
            "${mod},equal,setmfact,+0.05"
            "${mod}+ALT,Left,scroller_stack,left"
            "${mod}+ALT,Right,scroller_stack,right"

            # focus (arrows, plus the old niri letters)
            "${mod},h,focusdir,left"
            "${mod},j,focusdir,down"
            "${mod},k,focusdir,up"
            "${mod},y,focusdir,right"

            # tags (workspaces)
            "${mod},Page_Down,viewtoright"
            "${mod},Page_Up,viewtoleft"
            "${mod},u,viewtoright"
            "${mod},l,viewtoleft"
            "${mod}+CTRL,Page_Down,tagtoright"
            "${mod}+CTRL,Page_Up,tagtoleft"
            "${mod}+CTRL,u,tagtoright"
            "${mod}+CTRL,i,tagtoleft"

            # screenshots
            "CTRL,Home,spawn,${screenshot} region"
          ]
          ++ arrows mod "focusdir"
          ++ arrows "${mod}+CTRL" "exchange_client"
          ++ arrows "${mod}+SHIFT" "focusmon"
          ++ arrows "${mod}+SHIFT+CTRL" "tagmon"
          ++ lib.concatMap (i: [
            "${mod},${toString i},view,${toString i}"
            "${mod}+CTRL,${toString i},tag,${toString i}"
          ]) tags
          ++ shellBinds;
        # Mouse binds
        mousebind = [
          "${mod},btn_left,moveresize,curmove"
          "${mod},btn_right,moveresize,curresize"
        ];
        # media keys: also work on the lock screen
        bindl = [
          "NONE,XF86AudioRaiseVolume,spawn,${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
          "NONE,XF86AudioLowerVolume,spawn,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          "NONE,XF86AudioMute,spawn,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
          "NONE,XF86AudioMicMute,spawn,${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          "NONE,XF86AudioPlay,spawn,${playerctl} play-pause"
          "NONE,XF86AudioNext,spawn,${playerctl} next"
          "NONE,XF86AudioPrev,spawn,${playerctl} previous"
          "NONE,XF86AudioStop,spawn,${playerctl} stop"
          "NONE,XF86MonBrightnessUp,spawn,${brightness "up"}"
          "NONE,XF86MonBrightnessDown,spawn,${brightness "down"}"
        ];
      } // lib.optionalAttrs (cfg.mango.monitorRules != [ ]) {
        monitor_rule = cfg.mango.monitorRules;
      };
    };
  };
}
