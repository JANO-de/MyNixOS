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

  # mwifiex fails the EAPOL 4-way handshake when the AP enforces PMF (802.11w)
  # or negotiates it in a WPA2/WPA3 transition: it associates, sends EAPOL to
  # the AP and drops immediately. Default PMF OFF for every connection.
  environment.etc."NetworkManager/conf.d/00-surface-pmf.conf".text = ''
    [connection]
    802-11-wireless-security.pmf=0
  '';

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