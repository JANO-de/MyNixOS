# HALOS1 = Microsoft Surface Pro 5 (2017, i5-7300U / 8 GB / 128 GB): lean tablet host.
# niri (chronos fork) + the chronos shell, SDDM greeter with an on-screen
# keyboard, lean program set. Deployed from the desktop over SSH.
#
#   default.nix       this file: identity, disk, SP5 quirks, session, memory
#   network-aula.nix  school-network proxy dispatcher
{ config, pkgs, lib, inputs, ... }:

# !!!! To revert to niri/chronos: sed -i '55s|"mango"|"niri"|; 56s|"dynisland"|"chronos"|' hosts/surface/default.nix
#ip routegit add -A && sudo nixos-rebuild switch --flake .#surface

let
  # Fully transparent cursor theme: every cursor name Adwaita knows points at
  # one 1x1 transparent image, so a touch-only Surface shows no pointer. Switch
  # to Adwaita in the session when using the Type Cover touchpad.
  blankCursor = pkgs.runCommand "blank-cursor"
    {
      nativeBuildInputs = [ (pkgs.xcursorgen or pkgs.xorg.xcursorgen) pkgs.python3 ];
    }
    ''
      d=$out/share/icons/blank
      mkdir -p $d/cursors && cd $d
      python3 - <<'PY'
      import struct, zlib
      def chunk(t, b):
          c = struct.pack(">I", len(b)) + t + b
          return c + struct.pack(">I", zlib.crc32(t + b) & 0xffffffff)
      png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0)) \
          + chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\x00")) + chunk(b"IEND", b"")
      open("blank.png", "wb").write(png)
      PY
      echo "1 0 0 blank.png" > cfg
      xcursorgen cfg cursors/blank
      rm blank.png cfg
      for f in $(ls ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/cursors); do
        [ "$f" = blank ] || ln -s blank cursors/$f
      done
      printf '[Icon Theme]\nName=blank\n' > index.theme
    '';
in
{
  imports = [
    # linux-surface kernel, IPTS touch/pen, Marvell wifi firmware, thermald, S0ix.
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel

    ../../modules/core.nix
    ../../modules/hardware.nix
    ../../modules/services.nix
    ../../modules/programs.nix
    ../../modules/desktop
    ./network-aula.nix
  ];

  networking.hostName = "surface";

  # ---- session -------------------------------------------------------------
  modules.desktop = {
    session = "hyprland"; # Hyprland (UWSM) + Halo; the newest generation is always the default boot entry
    shell = "halo";
    autoMode = true; # tablet/desktop from attached keyboards (halo-autokbd)
    haloGreeter.enable = true; # Halo greetd login screen instead of SDDM (see greeter.nix)
    haloSplash.enable = true; # quiet boot + Halo ring splash
    droidloom.enable = true; # Android apps in native windows
  };
  modules.programs.profile = "lean";
  hardware.nvidia.enable = false; # Intel HD 620 only

  modules.desktop.hyprlandMode = "tablet"; # the Surface starts in tablet mode (see HYPRLAND_PLAN.md)

  # Deskflow: this tablet joins the laptop's server.
  modules.programs.deskflow = {
    role = "client";
    serverAddress = "laptop";
  };

  # Deploys build on the desktop and push here over SSH. Those paths are
  # unsigned, so the Surface's Nix rejects them ("lacks a signature by a
  # trusted key") unless the copying user is trusted.
  nix.settings.trusted-users = [ "root" "jano" ];

  # ---- disk: by label, no hardware-configuration.nix (UUIDs never committed) ---
  # mkfs.fat -F32 -n NIXBOOT <p1>; mkfs.ext4 -L NIXROOT <p2>
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };
  # The UEFI shows no boot menu of its own, so keep systemd-boot's short.
  boot.loader.timeout = 2;

  # ---- memory: 8 GB RAM / 128 GB disk ------------------------------------------
  # zram below half of RAM (overrides modules/core.nix), plus an 8 GB swapfile
  # for suspend/hibernate headroom (created on first activation). Verify a real
  # hibernate/resume cycle before relying on it.
  zramSwap = {
    memoryPercent = lib.mkForce 50;
    memoryMax = lib.mkForce 4294967296; # 4 GiB
  };
  swapDevices = [ { device = "/swapfile"; size = 8192; } ];
  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";

  # Daily autoupgrade builds are too heavy here; deploy from the PC instead.
  system.autoUpgrade.enable = lib.mkForce false;

  # keep the 128 GB disk from filling up
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };
  nix.settings.auto-optimise-store = true;

  # ---- lean services -------------------------------------------------------------
  modules.services.powertop.enable = true;
  modules.services.smartd.enable = true;

  # ---- SP5 hardware quirks ---------------------------------------------------------
  # Panel Self Refresh blanks the eDP output on this panel.
  boot.kernelParams = [ "i915.enable_psr=0" "cfg80211.ieee80211_regdom=ES" ];

  # iHD VA-API driver (intel-media-driver), right for Kaby Lake (HD 620). It
  # also drops nixos-hardware's legacy intel-vaapi-driver (i965) and intel-ocl,
  # whose upstream source URL now returns 403 and fails the whole build.
  hardware.intelgpu.vaapiDriver = "intel-media-driver";

  # wifi: Marvell 88W8997 (mwifiex_pcie). Power saving is flaky on this chip.
  networking.networkmanager.wifi.powersave = false;
  # Without the regulatory database mwifiex stays on the world domain and 5 GHz
  # channels are passive-only / hidden.
  hardware.wirelessRegulatoryDatabase = true;
  # Phone hotspots often ship a dead DNS relay; always try public DNS first.
  networking.networkmanager.insertNameservers = [ "1.1.1.1" "8.8.8.8" ];

  # The radio ends up soft-blocked after failed activations and nothing clears
  # it; clear it every boot so it is recoverable without a keyboard.
  systemd.services.rfkill-unblock-wifi = {
    description = "Clear stale wifi soft-blocks left by failed activations";
    before = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock wifi
    '';
  };

  # mwifiex fails the EAPOL handshake when the AP enforces PMF (802.11w).
  environment.etc."NetworkManager/conf.d/00-surface-pmf.conf".text = ''
    [connection]
    802-11-wireless-security.pmf=0
  '';
  # Some hotspots cap packets below 1500 (seen: 1358); a lower MTU avoids stalls.
  environment.etc."NetworkManager/conf.d/10-wifi-mtu.conf".text = ''
    [connection]
    802-11-wireless.mtu=1340
  '';

  # buttons: power, volume up/down (GPIO keys on ACPI MSHW0040).
  # soc_button_array's probe runs before the ACPI namespace is ready and is never
  # retried, leaving the buttons dead. Re-insert the module once udev settled.
  systemd.services.surface-button-bind = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    unitConfig.ConditionPathExists = "/sys/bus/acpi/devices/MSHW0040:00";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "-${pkgs.kmod}/bin/modprobe -r soc_button_array";
      ExecStartPost = "${pkgs.kmod}/bin/modprobe soc_button_array";
    };
  };
  # Mark the GPIO button nodes as keyboards so the compositor doesn't drop them.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", KERNELS=="MSHW0040:00", ENV{ID_INPUT_KEYBOARD}="1"
    SUBSYSTEM=="hidraw", ACTION=="change", KERNELS=="*045E:001F*", TAG+="systemd"
  '';
  services.logind.settings.Login.HandlePowerKey = "poweroff";

  # input
  services.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
  };
  hardware.sensor.iio.enable = true; # accelerometer (iio-sensor-proxy)

  # pen + touch (IPTS, handled by iptsd)
  services.iptsd = {
    enable = true;
    config = {
      Touchscreen = {
        DisableOnPalm = false;
        DisableOnStylus = true; # no touch while the pen is hovering/drawing
      };
      Stylus.Disable = false;
    };
  };
  # iptsd@ is bound to dev-hidraw0.device, which flaps/never forms on this box,
  # so systemd stops the service <1s after start. Drop the device binding and
  # keep it running; Restart covers a real hidraw re-creation. iptsd also hangs
  # on stop (SIGKILL after 90s); shorten that.
  systemd.services."iptsd@" = {
    restartIfChanged = false;
    unitConfig = {
      BindsTo = lib.mkForce ""; # empty value clears the inherited BindsTo=%i.device
      StopWhenUnneeded = lib.mkForce "no";
      # 4 failures in 60 s = firmware stuck: hand over to iptsd-recover (reloads the ipts driver).
      StartLimitIntervalSec = lib.mkForce 60;
      StartLimitBurst = lib.mkForce 4;
      OnFailure = [ "iptsd-recover.service" ];
    };
    serviceConfig = {
      TimeoutStopSec = lib.mkForce "5s";
      Restart = lib.mkForce "on-failure";
      RestartSec = lib.mkForce "3s";
    };
  };
  # Recovery for the boot race where the touch firmware stops answering (-11):
  # reload the ipts driver, then start iptsd again. Max 3 runs per 10 min.
  systemd.services.iptsd-recover = {
    description = "Reload ipts driver and restart iptsd";
    unitConfig = {
      StartLimitIntervalSec = 600;
      StartLimitBurst = 3;
    };
    path = [ pkgs.kmod pkgs.systemd pkgs.gawk pkgs.coreutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      units=$(systemctl list-units --all --plain --no-legend 'iptsd@*' | awk '{print $1}')
      for u in $units; do systemctl stop "$u" || true; done
      modprobe -r ipts || true
      sleep 2
      modprobe ipts
      sleep 4
      systemctl reset-failed 'iptsd@*' || true
      for u in $units; do systemctl start "$u"; done
    '';
  };
  services.udev.packages = [ pkgs.libwacom-surface ];

  # storage / security
  services.fstrim.enable = true; # TRIM on the 128 GB NVMe
  security.tpm2.enable = true; # Infineon TPM 2.0 (systemd-cryptenroll --tpm2)
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # ---- tablet session ---------------------------------------------------------------
  environment.sessionVariables = {
    XCURSOR_SIZE = "36";
    XCURSOR_THEME = "blank";
  };
  environment.pathsToLink = [ "/share/icons" ]; # so XCURSOR_THEME resolves
  environment.systemPackages = [
    blankCursor
    pkgs.libwacom-surface
    pkgs.wl-clipboard
  ];

  system.stateVersion = "26.05";
}
