{ self, inputs, ... }: 
{
  flake.nixosModules.gamingcore = { pkgs, ...}: 
  {
    hardware.graphics = {
      enable = true;
    };

    boot = {
      initrd = {
        # Remove "nvidia" from here. 
        # Use "i915" for Intel or "amdgpu" for AMD if you have integrated graphics.
        kernelModules = [ "i915" ]; 
      };

      kernelParams = [
        "quiet"
        "splash"
        "nvidia-drm.modeset=1" # This helps Nvidia/Plymouth play nice
        "udev.log_level=3"
        "vt.global_cursor_default=0"
      ];
    };

    nix.settings = {
      substituters = ["https://nix-gaming.cachix.org"];
      trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
    };
  };
}