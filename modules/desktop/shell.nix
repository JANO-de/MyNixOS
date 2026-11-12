# Shell switch: modules.desktop.shell = one of the names in the enum below, or "none".
# The shell is the bar, panels, notifications and wallpaper layer. It is independent of the
# compositor (modules.desktop.compositor: niri or mangowm).
#
#   noctalia   v5 (C++). Own module and systemd user unit under niri.
#   ambxst     Quickshell, flake package.   caelestia  Quickshell, flake package.
#   others     Not packaged. You clone them yourself, Nix only provides quickshell and starts
#              them. Each needs to sit in ~/.config/quickshell/<name>/ (aureli uses its own
#              `au` launcher). Repo URLs are in `cloned` below and are printed as a build warning.
#
# Ambxst, Caelestia and Aureli (eqsh) are written for Hyprland; on niri or mango they may run only
# partly (UNVERIFIED). Whisker, NibrasShell, ChromeX, Sleex and Zaphkiel: how they start is
# UNVERIFIED, `quickshell -c <name>` is an assumption.
# Under niri the shell is a systemd user unit (niri.service pulls in graphical-session.target).
# mangowm never starts that target, so its config runs `desktop-shell` (exec-once), a tiny
# launcher on PATH that execs whichever shell is selected. Compositor configs never name a shell.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.desktop;
  sys = pkgs.stdenv.hostPlatform.system;
  noctalia = inputs.noctalia.packages.${sys}.default;
  ambxst = inputs.ambxst.packages.${sys}.default;
  caelestia = inputs.caelestia-shell.packages.${sys}.default;
  quickshell = pkgs.quickshell;

  # Shells you install yourself: name = where to get it.
  cloned = {
    aureli = "https://github.com/eq-desktop/eqsh (its install guide: https://eqsh-wiki.github.io/install, needs `au` on PATH)";
    nucleus = "https://github.com/xZepyx/nucleus-shell (git clone into ~/.config/quickshell/nucleus)";
    whisker = "https://github.com/corecathx/whisker (git clone into ~/.config/quickshell/whisker)";
    nibras = "https://github.com/AhmedSaadi0/NibrasShell (git clone into ~/.config/quickshell/nibras)";
    chromex = "https://github.com/catdeal3r/chromex (git clone into ~/.config/quickshell/chromex)";
    sleex = "https://www.axos-project.com/docs/guides/sleex (install into ~/.config/quickshell/sleex)";
    zaphkiel = "https://github.com/Rexcrazy804/Zaphkiel (install into ~/.config/quickshell/zaphkiel)";
  };
  quickshellNames = lib.remove "aureli" (builtins.attrNames cloned);

  commands = {
    noctalia = "${noctalia}/bin/noctalia";
    ambxst = "${ambxst}/bin/ambxst";
    caelestia = "${caelestia}/bin/caelestia-shell";
    aureli = "au run";
  }
  // lib.genAttrs quickshellNames (name: "${quickshell}/bin/quickshell -c ${name}");

  extraPackages = {
    ambxst = [ ambxst ];
    caelestia = [ caelestia ];
    aureli = [ quickshell ];
  }
  // lib.genAttrs quickshellNames (_: [ quickshell ]);

  launcher = pkgs.writeShellScriptBin "desktop-shell" ''
    exec ${commands.${cfg.shell}} "$@"
  '';
in
{
  options.modules.desktop.shell = lib.mkOption {
    type = lib.types.enum (
      [
        "noctalia"
        "ambxst"
        "caelestia"
      ]
      ++ builtins.attrNames cloned
      ++ [ "none" ]
    );
    default = "noctalia";
    description = "Shell started in the session. Needs a compositor; \"none\" starts no shell.";
  };

  config = lib.mkIf (cfg.enable && cfg.compositor != "none" && cfg.shell != "none") (
    lib.mkMerge [
      { environment.systemPackages = [ launcher ]; }

      (lib.mkIf (cfg.shell == "noctalia") {
        services.noctalia-shell = {
          enable = true;
          package = noctalia;
        };
      })

      (lib.mkIf (cfg.shell != "noctalia") {
        environment.systemPackages = extraPackages.${cfg.shell};
        warnings = lib.optional (builtins.hasAttr cfg.shell cloned) "modules.desktop.shell = \"${cfg.shell}\" is not packaged: install it yourself from ${cloned.${cfg.shell}}. Nix only starts it.";
        systemd.user.services.desktop-shell = lib.mkIf (cfg.compositor == "niri") {
          description = "Desktop shell (${cfg.shell})";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${launcher}/bin/desktop-shell";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      })

      (lib.mkIf (cfg.shell == "ambxst") {
        # Ambxst's screen recorder only gets the portal backend without this.
        programs.gpu-screen-recorder.enable = true;
      })
    ]
  );
}
