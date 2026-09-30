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