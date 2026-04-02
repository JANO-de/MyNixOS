{ self, inputs, ... }: 
{
  flake.nixosModules.gamingcore = { pkgs, ...}: 
  {
    hardware.graphics = {
      enable = true;
    };

    boot.initrd = {
      # 1. We use availableKernelModules for external/proprietary drivers
      availableKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      
      # 2. Keep the standard ones in kernelModules if you want them forced
      kernelModules = [ "i915" ]; # Example: keep your Intel/AMD here, but NOT nvidia
    };

    # 3. This is the crucial part: it tells NixOS to actually 
    # include the nvidia package in the initrd
    boot.initrd.extraFiles = { }; # Just a placeholder to show where logic goes
    boot.initrd.services.udev.binPackages = [ pkgs.nvidia-vaapi-driver ]; # Optional

    # Ensure the kernel knows to use Nvidia for the console
    boot.kernelParams = [ "nvidia-drm.modeset=1" ];

    nix.settings = {
      substituters = ["https://nix-gaming.cachix.org"];
      trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
    };
  };
}