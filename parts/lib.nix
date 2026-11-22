# Shared helpers.
#   flake.lib.commonModules  every feature module that is switched by an option (or is plain
#                            config every host wants). A host gets all of them and turns the
#                            ones it needs on with modules.*; the order is the old loader's.
#   flake.lib.mkHost         the one place that builds a nixosSystem. Strings in `modules` are
#                            names under flake.nixosModules, anything else is passed through.
# Host-only modules (no enable switch, e.g. server-vikunja) are listed by the host itself.
{
  inputs,
  self,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  theme = import ./theme/_palette.nix;

  commonModules = [
    # core
    "core-boot"
    "core-nix"
    "core-users"
    "core-locale"
    "core-fonts"
    "core-shell"
    "core-home-manager"
    # desktop
    "desktop-compositor"
    "desktop-dotfiles"
    "desktop-session"
    "desktop-shell"
    # dev
    "dev-fullstack"
    "dev-java"
    # hardware
    "hardware"
    "hardware-bluetooth"
    "hardware-firmware"
    "hardware-drives"
    "hardware-nvidia"
    "hardware-cachyos"
    "hardware-openrgb"
    # programs
    "programs"
    "programs-lean"
    "programs-full"
    "programs-apps"
    "programs-office"
    "programs-files"
    "programs-ai"
    "programs-spotify"
    "programs-deskflow"
    "orchard"
    "niXscout"
    "nyaa-si"
    "neo-mangal"
    "vid-dl"
    "programs-ytm-rs"
    "programs-ytm-player"
    "programs-ytui"
    "programs-deviload"
    # server
    "server-books"
    "server-caddy-lan"
    "server-caddy"
    "server-freshrss"
    "server-homepage"
    "server-it-tools"
    "server-jellyfin"
    "server-kavita"
    "server-media-stack"
    "server-media-tracker"
    "server-open-webui"
    "server-openwa"
    "server"
    "server-stirling-pdf"
    "server-uptime-kuma"
    # services
    "services"
    "services-networking"
    "services-audio"
    "services-printing"
    "services-ssh"
    "services-flatpak"
    "services-sunshine"
    "services-waydroid"
    "services-powertop"
    "services-smartd"
    "services-artcraft"
    "services-virtualbox"
    "services-qmk"
    "services-tailscale"
    # theme
    "theme"
    # gaming
    "gaming"
  ];

  resolve = m: if builtins.isString m then self.nixosModules.${m} else m;
in
{
  flake.lib = {
    inherit commonModules;

    mkHost =
      { modules }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs theme; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.forge.nixosModules.default
          inputs.niri-flake.nixosModules.niri
          inputs.mangowc.nixosModules.mango
          inputs.noctalia.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-gaming.nixosModules.platformOptimizations
        ]
        ++ map resolve (lib.unique modules)
        ++ [
          {
            nixpkgs.overlays = [
              inputs.rust-overlay.overlays.default
              self.overlays.default
            ];
          }
        ];
      };
  };
}
