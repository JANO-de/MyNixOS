# Microsoft Surface Pro 5 (2017, i5-7300U / 8GB / 128GB) — custom extras on top
# of nixos-hardware's microsoft-surface-pro-intel module (imported in
# hosts/surface/default.nix).
#
# nixos-hardware provides the heavy lifting:
#   * linux-surface patched kernel (6.19.x) — surface_aggregator (SAM), IPTS,
#     DTX perf modes, S0ix (mem_sleep_default=deep)
#   * services.iptsd              -> touch + pen on the Intel IPTS controller
#   * hardware.enableRedistributableFirmware -> Marvell 88W8997 wifi + mwifiex_pcie
#   * thermald + surface-control, Intel i915 GPU setup
#
# This file only carries the SP5 specifics that module does not cover.
{ config, pkgs, lib, ... }:

{
  # --- wifi: Marvell 88W8997 via the in-tree mwifiex_pcie driver ---
  # Driver + firmware come from nixos-hardware's redistributable firmware flag.
  # mwifiex's power saving is flaky on this chip (drops, long reassocs), so keep
  # the radio always on.
  networking.networkmanager.wifi.powersave = false;

  # The radio still ends up soft-blocked in practice: wpa_supplicant logs
  # "rfkill: WLAN soft blocked" whenever an activation dies mid-handshake (an AP
  # that never finishes associating, a wrong PSK, an EAPOL timeout), and on this
  # chip nothing clears it afterwards -- the interface stays down and the SSID
  # vanishes from scans until it is unblocked by hand. Clear it on every boot so
  # a failed attempt is recoverable without a keyboard.
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

  # mwifiex fails the EAPOL 4-way handshake when the AP enforces PMF (802.11w)
  # or negotiates it in a WPA2/WPA3 transition: it associates, sends EAPOL to
  # the AP and drops immediately. Default PMF OFF for every connection.
  environment.etc."NetworkManager/conf.d/00-surface-pmf.conf".text = ''
    [connection]
    802-11-wireless-security.pmf=0
  '';

  # --- Aula_1CFGS: internet only via a proxy, and it must not take the default route ---
  # That network's "gateway" 192.168.8.1 is a Debian host running Squid, not a
  # router: it answers DHCP and DNS (external names resolve fine) but forwards
  # nothing, so every packet to the internet is dropped. The one way out is the
  # proxy on 192.168.8.1:8080. Port 3128 is also open but its ACL returns
  # ERR_ACCESS_DENIED for us, so 8080 is the working one.
  #
  # Two consequences:
  #   * Requests have to go out via Squid, so the session gets http_proxy/
  #     https_proxy pointing at 192.168.8.1:8080 whenever this network is the
  #     active one, and loses them when it is not. Set by the dispatcher script
  #     below, because this NetworkManager cannot store the setting itself:
  #     `nmcli connection modify` only exposes method/browser-only/pac-*, and a
  #     hand-written [proxy] block in the profile keyfile is parsed and then
  #     discarded (`proxy.method` stays "none" after `nmcli connection reload`).
  #   * ipv4.never-default on the profile, because the wifi's DHCP default route
  #     has a lower metric (600) than the USB ethernet dongle (750). Without it,
  #     merely joining Aula_1CFGS pulls all traffic onto the dead uplink and the
  #     tablet appears to lose the network. The profile itself lives in
  #     /etc/NetworkManager/system-connections, which NixOS does not manage, so
  #     the PSK is not committed to this repository.
  environment.etc."NetworkManager/dispatcher.d/10-aula-proxy".text = ''
    #!/bin/sh
    # $1 is the interface and $2 the action. The connection id is not among the
    # positional arguments -- NetworkManager passes it in the environment as
    # CONNECTION_ID, so match on that rather than on $1.
    [ "$2" = "up" ] || [ "$2" = "down" ] || exit 0
    [ "$CONNECTION_ID" = "Aula_1CFGS" ] || exit 0

    # Squid is on this wifi's own subnet: exempt it, or the proxy call itself
    # gets sent to the proxy.
    no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,.local"
    export no_proxy NO_PROXY="$no_proxy"
    proxy="http://192.168.8.1:8080"

    # The dispatcher runs as root, from NetworkManager-dispatcher.service, which
    # has a near-empty PATH: unqualified awk/loginctl are not found there. Every
    # external command is therefore spelled out with its store path.
    #
    # Write the variables where the session can pick them up, which is the only
    # place they are of any use. list-sessions prints
    # "SESSION UID USER SEAT LEADER CLASS ...", so CLASS is field 6 and UID is
    # field 2 -- not the 3rd field, which is the user *name*.
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
      # Owned by the user, not root: it has to be readable from their shell.
      chown "$uid" "$target.new"
      chmod 600 "$target.new"
      mv "$target.new" "$target"
    else
      # Leaving the network takes the proxy with it: the dongle reaches the
      # internet directly, and a stale proxy would break it.
      rm -f "$target"
    fi
  '';
  environment.etc."NetworkManager/dispatcher.d/10-aula-proxy".mode = "0755";

  # --- buttons: power, volume up/down ---
  # On this generation all three buttons are GPIO keys on the ACPI device
  # MSHW0040, not a uinput device: soc_button_array creates two "gpio-keys"
  # nodes under it (one with KEY_VOLUMEUP/KEY_VOLUMEDOWN, one with KEY_POWER).
  #
  # surfacepro3_button also claims MSHW0040 and its probe failing here is
  # correct, not a bug: linux-surface's 0009-surface-button patch splits the two
  # drivers on whether the _DSM OEM-platform-revision method exists. It exists on
  # 5th-gen-and-newer firmware -> soc_button_array; it is absent on the SP4 /
  # Book 1 that still want surfacepro3_button.
  #
  # soc_button_array's probe calls that _DSM, which only answers correctly once
  # the ACPI namespace is fully initialised. udev's modalias autoload gets there
  # first, the probe is skipped, and the kernel never retries it on its own — so
  # at boot there is no node carrying KEY_POWER/KEY_VOLUME* anywhere and the
  # buttons are completely dead (nothing for logind, the session or keyd to see).
  # Re-inserting the module once udev has settled makes the probe succeed.
  systemd.services.surface-button-bind = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    unitConfig.ConditionPathExists = "/sys/bus/acpi/devices/MSHW0040:00";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # "-" tolerates the module already being bound (i.e. already working).
      ExecStart = "-${pkgs.kmod}/bin/modprobe -r soc_button_array";
      ExecStartPost = "${pkgs.kmod}/bin/modprobe soc_button_array";
    };
  };

  # Mutter decides whether a node is a keyboard from udev's ID_INPUT_KEYBOARD,
  # and input_id only sets ID_INPUT_KEY for these GPIO nodes (they emit nothing
  # but the three buttons). Without this, Wayland silently drops every event
  # they produce.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", KERNELS=="MSHW0040:00", ENV{ID_INPUT_KEYBOARD}="1"
  '';

  # The desktop owns the power key: logind's default action is "poweroff", and a
  # short press with a thumb on a 700 g tablet should not kill the session.
  # modules/desktop/power-button.nix grabs the input node and turns a short press
  # into a screen blank instead; "ignore" also covers the moment before that
  # daemon has grabbed the device, when "poweroff" would otherwise be live.
  services.logind.settings.Login.HandlePowerKey = "ignore";

  # --- touch ---
  # The Type Cover's trackpad follows the same rules as the other hosts.
  services.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
  };

  # --- storage / firmware ---
  # 128GB NVMe: TRIM keeps deleted blocks from permanently occupying the drive.
  services.fstrim.enable = true;

  # --- security ---
  # Infineon TPM 2.0. Gives us systemd-cryptenroll --tpm2, i.e. an encrypted
  # root that unlocks unattended (and measured/PCR-bound boot later if wanted).
  security.tpm2.enable = true;

  # --- power ---
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # --- misc ---
  # The Surface UEFI shows no boot menu of its own, so keep systemd-boot's short.
  boot.loader.timeout = 2;
}