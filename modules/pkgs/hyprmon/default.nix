{ lib, buildGoModule, fetchFromGitHub, makeWrapper }:

buildGoModule rec {
  pname = "hyprmon";
  version = "0.0.17";

  src = fetchFromGitHub {
    owner = "erans";
    repo = "hyprmon";
    rev = "v${version}";
    hash = "sha256-1rtmToVveAkNRqPR1gDCYIOS+nM9Ag+3T5QYJmdtbEg=";
  };

  vendorHash = "sha256-U2fw/1tnRwmd9qzEcrMduZbbNU67NbDhG2Id5IHj5js=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    mv $out/bin/hyprmon $out/bin/.hyprmon
    makeWrapper $out/bin/.hyprmon $out/bin/hyprmon \
      --run 'export HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.lua"'
  '';

  meta = {
    description = "TUI monitor configuration tool for Hyprland";
    homepage = "https://github.com/erans/hyprmon";
    license = lib.licenses.asl20;
    mainProgram = "hyprmon";
  };
}
