# nyaa-si package (Go, Bubbletea TUI + anacrolix/torrent). `src` is the flake input nyaa-si-src.
{
  lib,
  buildGoModule,
  makeWrapper,
  xdg-utils,
  src,
}:

buildGoModule (finalAttrs: {
  pname = "nyaa-si";
  version = "1.0.0";
  inherit src;

  # First build fails and prints "got: sha256-...": paste that value here.
  vendorHash = "sha256-/6KAHENJDXh6NH6ckol67hX1gS9AHWPbzZ4p8VVBlV8=";

  subPackages = [ "cmd" ];
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];

  doCheck = false;

  nativeBuildInputs = [ makeWrapper ];

  # The binary is built from ./cmd, so Go names it "cmd".
  postInstall = ''
    mv $out/bin/cmd $out/bin/nyaa-si
    wrapProgram $out/bin/nyaa-si --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}
  '';

  meta = {
    description = "nyaa.si TUI explorer and BitTorrent client with optional WireGuard";
    homepage = "https://codeberg.org/madLinux/nyaa-si";
    license = lib.licenses.mit;
    mainProgram = "nyaa-si";
  };
})
