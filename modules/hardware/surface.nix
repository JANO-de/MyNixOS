# Microsoft Surface Pro 5 (2017, i5-7300U / 8GB / 128GB) — extras on top of
# nixos-hardware's microsoft-surface-pro-intel (imported in hosts/surface/default.nix),
# which provides the linux-surface kernel, iptsd, redistributable firmware,
# thermald + surface-control and i915 setup.
{ config, pkgs, lib, ... }:

{
  # --- wifi: Marvell 88W8997 (mwifiex_pcie) ---
  # Power saving is flaky on this chip; keep the radio always on.
  networking.networkmanager.wifi.powersave = false;

  # The radio ends up soft-blocked after failed activations and nothing clears
  # it; clear it on every boot so it is recoverable without a keyboard.
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

  # mwifiex fails the EAPOL handshake when the AP enforces PMF (802.11w):
  # default PMF OFF for every connection.
  environment.etc."NetworkManager/conf.d/00-surface-pmf.conf".text = ''
    [connection]
    802-11-wireless-security.pmf=0
  '';

  # --- Aula_1CFGS: internet only via Squid proxy, must not take the default route ---
  # 192.168.8.1 answers DHCP/DNS but forwards nothing; the only way out is the
  # proxy on :8080 (3128 returns ERR_ACCESS_DENIED). The dispatcher below sets
  # proxy vars for the session while that network is active (NetworkManager here
  # cannot store the proxy setting itself). The profile (with PSK) lives in
  # /etc/NetworkManager/system-connections, unmanaged by NixOS, and must have
  # ipv4.never-default so the dead uplink doesn't win over the USB ethernet.
  environment.etc."NetworkManager/dispatcher.d/10-aula-proxy".text = ''
    #!/bin/sh
    # $1 = interface, $2 = action; the connection id arrives as CONNECTION_ID.
    [ "$2" = "up" ] || [ "$2" = "down" ] || exit 0
    [ "$CONNECTION_ID" = "Aula_1CFGS" ] || exit 0

    # Squid is on this subnet: exempt it so the proxy call isn't proxied.
    no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,.local"
    export no_proxy NO_PROXY="$no_proxy"
    proxy="http://192.168.8.1:8080"

    # Dispatcher has a near-empty PATH: use store paths for every command.
    # list-sessions columns: SESSION UID USER SEAT LEADER CLASS -> UID=$2, CLASS=$6.
    uid=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null \
      | ${pkgs.gawk}/bin/awk '$6 == "user" && $2 ~ /^[0-9]+$/ { print $2; exit }')
    [ -n "$uid" ] || exit 0
    runtime="/run/user/$uid"
    [ -d "$runtime" ] || exit 0
    target="$runtime/aula-proxy.env"

    if [ "$2" = "up" ]; then
      printf '%s\n' \
        "export http_proxy=$proxy https_proxy=$proxy HTTP_PROXY=$proxy HTTPS_PROXY=$proxy no_proxy=$no_proxy NO_PROXY=$no_proxy" \
        > "$target.new"
      chown "$uid" "$target.new"
      chmod 600 "$target.new"
      mv "$target.new" "$target"
    else
      # Leaving the network takes the proxy with it.
      rm -f "$target"
    fi
  '';
  environment.etc."NetworkManager/dispatcher.d/10-aula-proxy".mode = "0755";

  # --- buttons: power, volume up/down (GPIO keys on ACPI MSHW0040) ---
  # soc_button_array's probe runs before the ACPI namespace is ready (udev
  # autoload) and is never retried, leaving the buttons dead. Re-insert the
  # module once udev has settled. (surfacepro3_button failing here is correct.)
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
  '';

  # Plasma owns the power key (powerdevil); long press offers power-off.
  services.logind.settings.Login.HandlePowerKey = "poweroff";

  # --- display: force X11 (kwin_wayland drove nothing on this panel) ---
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.sddm.settings.Users.RememberLastSession = false;
  systemd.tmpfiles.rules = [ "r /var/lib/sddm/state.conf" ];
  # Panel Self Refresh causes blank eDP output on Surface.
  boot.kernelParams = [ "i915.enable_psr=0" ];

  # --- touch / tablet ---
  services.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
  };
  hardware.sensor.iio.enable = true;   # auto-rotate

  # --- dark QML pages fix ---
  environment.sessionVariables = {
    QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
    QT_QPA_PLATFORMTHEME = "kde";
  };

  environment.systemPackages = with pkgs; [
    kdePackages.qqc2-desktop-style
    kdePackages.breeze
    kdePackages.breeze-gtk
    kdePackages.plasma-integration
    kdePackages.kirigami-addons
    kdePackages.okular 
    kdePackages.kdeconnect-kde
    krita 
    xournalpp 
    rnote 
    kando 
    anki
  ];

  # --- storage / firmware ---
  services.fstrim.enable = true;       # TRIM on the 128GB NVMe

  # --- security ---
  security.tpm2.enable = true;         # Infineon TPM 2.0 (systemd-cryptenroll --tpm2)

  # --- power ---
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # --- misc ---
  boot.loader.timeout = 2;

  # --- 128GB / 8GB survival ---
  zramSwap.enable = true;
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 14d"; };
  nix.settings.auto-optimise-store = true;
  services.flatpak.enable = true;
}
