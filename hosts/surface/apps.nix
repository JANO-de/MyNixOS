# Study / tablet apps (touch-friendly Kirigami apps where possible).
# Names are looked up with `or null`, so a package missing from this nixpkgs is
# skipped instead of breaking evaluation, and so are packages nixpkgs marks
# insecure (usually an old bundled Electron, e.g. Obsidian). Skipped on purpose: kdenlive and
# rustdesk (heavy, use the desktop), gnome-pomodoro (pulls GNOME).
{ pkgs, lib, inputs, ... }:

let
  pick = set: names: lib.filter (p: p != null && !(p.meta.insecure or false)) (map (n: set.${n} or null) names);
in
{
  environment.systemPackages =
    pick pkgs [
      "opencode"
      "obsidian"     # markdown notes (unfree)
      "zotero"       # references
      "haruna"       # video
      "foliate"      # ebooks
      "libreoffice-qt"
      "brightnessctl"
      "libinput"
      "klassy"       # window decoration
    ]
    ++ [ inputs.nix-software-center.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center ]
    ++ pick pkgs.kdePackages [
      "kate"
      "plasma-keyboard"
      "gwenview"
      "elisa"
      "kclock"
      "merkuro"      # calendar / contacts
      "itinerary"
      "tokodon"
      "spectacle"
      "ark"
      "filelight"
    ];

  # Sync notes/projects with the desktop. Web UI: http://127.0.0.1:8384
  services.syncthing = {
    enable = true;
    user = "jano";
    dataDir = "/home/jano";
    openDefaultPorts = true;
  };

  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
}
