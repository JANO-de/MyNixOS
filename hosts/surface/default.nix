# Microsoft Surface Pro 5 tablet — lean Plasma 6 (Wayland) host.
# Uses the LEAN program set (modules/programs/lean.nix), not the full one.
#
#   default.nix       identity, memory/swap, services (this file)
#   filesystems.nix   disk layout by label (shared with surface-bootstrap)
#   hardware.nix      SP5 quirks: wifi, buttons, panel, power
#   network-aula.nix  school-network proxy dispatcher
#   tablet.nix        Plasma/SDDM session, greeter OSK, touch cursor
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # linux-surface kernel, IPTS touch/pen, Marvell wifi firmware, thermald, S0ix.
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel

    # Denial Wayland session (substituter configured in flake.nix nixConfig).
    inputs.denial.nixosModules.default

    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs/lean.nix

    ./filesystems.nix
    ./hardware.nix
    ./network-aula.nix
    ./tablet.nix
  ];

  networking.hostName = "surface";

  # Denial session, selectable at the SDDM login screen (Plasma stays default).
  programs.denial.enable = true;

  # Local tablet patches to Denial (all live in ./patches):
  #  - status bar: the always-on drag strip scales with the viewport
  #    (colorOsShadeScaleForViewport), so on this 2736x1824 panel its opaque hit
  #    region grows to ~260px and swallows taps meant for the top launcher rows.
  #    Rebuild it translucent + pointer-transparent so taps fall through while
  #    vertical drags still open/close the shade.
  #  - shell OSK: add a number row, Left/Right arrows, Tab, Esc, forward Delete,
  #    a Ctrl+V paste key, ñ on the letter rows and an emoji/Spanish layer.
  #  - compositor: commit shell-keyboard text through text-input-v3 so the OSK
  #    can type arbitrary Unicode (accents, emoji). Terminals and Xwayland have
  #    no text-input session and keep the US keycode fallback.
  #    (The 900x620 Settings bug was NOT a compositor/Dart bug — see
  #    HANDOFF-denial-surface-current.md session 6. Diagnostic patches removed;
  #    settingsApp no longer needs its own override.)
  programs.denial.package =
    let
      patchedShell = pkgs.denial.dartShell.override {
        # The Flutter builder unpacks by source name (sourceRoot is
        # "source/dart_shell"), so this must be called "source".
        src = pkgs.runCommand "source"
          { nativeBuildInputs = [ pkgs.patch ]; }
          ''
            cp -a ${pkgs.denial.dartShell.src} $out
            chmod -R u+w $out
            patch -p1 -d $out --no-backup-if-mismatch \
              < ${./patches/denial-status-bar-tap.patch}
            patch -p1 -d $out --no-backup-if-mismatch \
              < ${./patches/denial-osk-gboard.patch}
          '';
      };
      patchedCompositor = pkgs.callPackage (inputs.denial.outPath + "/nix/compositor.nix") {
        src = pkgs.runCommand "source"
          { nativeBuildInputs = [ pkgs.patch ]; }
          ''
            cp -a ${inputs.denial.outPath} $out
            chmod -R u+w $out
            patch -p1 -d $out --no-backup-if-mismatch \
              < ${./patches/denial-unicode-text.patch}
          '';
        version = pkgs.denial.version;
        buildIdentity = "nix.surface-unicode-inset";
      };
    in
    (pkgs.runCommand "denial-patched"
      { }
      ''
        cp -a ${pkgs.denial} $out
        chmod -R u+w $out
        rm -rf $out/lib/denial/flutter
        cp -a ${patchedShell} $out/lib/denial/flutter
        # settingsApp is left as plain pkgs.denial's own build — no patch
        # needed there anymore, see comment above.
        # Swap the compositor for the Unicode-capable build.
        rm -f $out/bin/deniald
        cp ${patchedCompositor}/bin/deniald $out/bin/deniald
        # denial-session resolves the bundle relative to its own path, so point
        # the session entry point (and its siblings) at this rebuilt package.
        substituteInPlace $out/share/wayland-sessions/denial.desktop \
          --replace-fail '${pkgs.denial}' "$out"
        # The makeWrapper launcher hardcodes the original .denial-session-wrapped
        # path; without this it would exec the unpatched compositor/bundle even
        # though the .desktop points at this package.
        substituteInPlace $out/bin/denial-session \
          --replace-fail '${pkgs.denial}' "$out"
        # The launcher hard-fails when `systemctl --user cat denial-session.target`
        # fails. On a cold boot the user manager is only just spawned by the
        # session and may not have scanned /etc/systemd/user yet, so the check
        # races and bounces the first login. The target merely groups the session
        # services, so warn instead of aborting the session.
        substituteInPlace $out/bin/.denial-session-wrapped \
          --replace-fail \
            "die 'denial-session.target is not available to the systemd user manager'" \
            "printf 'denial-session: warning: denial-session.target not visible to the user manager yet; continuing' >&2"
        # These .desktop files were substituted at plain pkgs.denial's own
        # build time (Exec=/TryExec= point into pkgs.denial's store path), so
        # the cp -a above carries stale paths unless we fix them too — this
        # was the root cause of Settings launching unpatched code.
        substituteInPlace $out/share/applications/dev.denial.Settings.desktop \
          --replace-fail '${pkgs.denial}' "$out"
        substituteInPlace $out/share/applications/dev.denial.Welcome.desktop \
          --replace-fail '${pkgs.denial}' "$out"
      '')
    // { providedSessions = [ "denial" ]; };

  # Intel HD 620 only.
  hardware.nvidia.enable = false;

  # Deploys build here and push to the Surface over SSH (see flake mkHost
  # usage). Those paths are unsigned, so the Surface's Nix rejects them with
  # "lacks a signature by a trusted key" unless the copying user is trusted.
  # Same as hosts/desktop/default.nix.
  nix.settings.trusted-users = [ "root" "jano" ];

  # --- lean services (the lampp workbench lives on the laptop) ---
  # xampp: off by default (enabled only on laptop)
  modules.services.powertop.enable = true;
  modules.services.smartd.enable = true;
  modules.services.waydroid.enable = false;

  # --- memory: 8GB RAM / 128GB disk ---
  # Keep zram below half of RAM (overrides modules/core/base.nix), plus an 8GB
  # swapfile for suspend/hibernate headroom (created on first activation).
  zramSwap = {
    memoryPercent = lib.mkForce 50;
    memoryMax = lib.mkForce 4294967296; # 4 GiB
  };
  swapDevices = [ { device = "/swapfile"; size = 8192; } ];
  # Hibernate to the swapfile: verify a real hibernate/resume cycle before
  # relying on it.
  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";

  # Daily autoupgrade builds on 8GB RAM / 128GB disk are too heavy for the
  # tablet; deploy from the PC instead.
  system.autoUpgrade.enable = lib.mkForce false;

  # --- keep the 128GB disk from filling up ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";
  modules.programs.deskflow.role = "client";
  modules.programs.deskflow.serverAddress = "laptop";
}
