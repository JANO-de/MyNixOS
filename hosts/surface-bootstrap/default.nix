{ config, pkgs, lib, ... }:

{
  # Minimal throwaway system to get the SP5 booted so the *real* `surface`
  # config can be built on it (the full 15 GB closure cannot fit the live
  # USB's RAM-backed store). Installed with `nixos-install --flake .#surface-bootstrap`,
  # then upgraded in place with:
  #   nixos-rebuild switch --flake ~/MyNixOS#surface \
  #     --option extra-substituters http://<desktop-ip>:5000
  #
  # Same filesystem labels as the `surface` config, so the filesystems stay put.

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "surface";
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Marvell 88W8997 Wi-Fi firmware (and everything else redistributable).
  hardware.enableRedistributableFirmware = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  console.keyMap = "es";

  users.users.jano = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # THROWAWAY password, only for the initial boot. Generate + set a real one
    # with `passwd jano` right after the first `nixos-rebuild switch`.
    initialPassword = "bde92496e9dbd256";
  };
  users.users.root.initialPassword = "bde92496e9dbd256";

  # Same layout as `surface`: 512MB FAT32 labelled NIXBOOT, rest ext4 NIXROOT.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  system.stateVersion = "26.05";
}