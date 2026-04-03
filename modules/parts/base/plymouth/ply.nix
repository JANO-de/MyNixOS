{ self, inputs, ... }: {
  flake.nixosModules.ply = { pkgs, config, lib, ... }: 
    let
      # Use runCommand instead of stdenv.mkDerivation to avoid Bash dependencies
      hunt-showdown-plymouth = pkgs.runCommand "hunt-showdown-plymouth" {
        src = pkgs.fetchFromGitHub {
          owner = "Anxhul10";
          repo = "huntShowdown-plymouth";
          rev = "master";
          sha256 = "sha256-zBaz6LWan6ExXfWv5nRGjamfV47SpfQSxvS/jQ8G4Ck="; 
        };
      } ''
        # 1. Create the destination folder
        # The theme name in the files is 'hunt', so the folder MUST be 'hunt'
        mkdir -p $out/share/plymouth/themes/huntShowdown-plymouth
        
        # 2. Copy the contents
        cp -r $src/* $out/share/plymouth/themes/huntShowdown-plymouth
        chmod -R +w $out/share/plymouth/themes/huntShowdown-plymouth
        
        # 3. Fix the hardcoded paths inside the theme files
        # We use 'sed' to point Plymouth to the Nix Store instead of /usr
        sed -i "s|/usr/share/plymouth/themes/huntShowdown-plymouth|$out/share/plymouth/themes/huntShowdown-plymouth|g" $out/share/plymouth/themes/huntShowdown-plymouth/huntShowdown-plymouth.plymouth
        sed -i "s|/usr/share/plymouth/themes/huntShowdown-plymouth|$out/share/plymouth/themes/huntShowdown-plymouth|g" $out/share/plymouth/themes/huntShowdown-plymouth/huntShowdown-plymouth.script
      '';
    in
    {
      boot.plymouth = {
        enable = true;
        themePackages = [ hunt-showdown-plymouth ];
        # This must match the filename 'hunt.plymouth' inside the folder
        theme = "huntShowdown-plymouth"; 
      };

      # Essential for NVIDIA + Plymouth
      boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      boot.kernelParams = [ "quiet" "splash" "nvidia-drm.modeset=1" ];
    };
}