{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "localsend-cli";
  version = "1.18.2";

  src = fetchFromGitHub {
    owner = "localsend";
    repo = "localsend";
    rev = "v${version}";
    hash = "sha256-hP4whBkBQ/FEnUOjgeC+HIzrWhtbME6HGxmwwvTSSeI=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  cargoBuildFlags = [ "-p" "localsend-cli" ];
  cargoTestFlags = [ "-p" "localsend-cli" ];

  meta = {
    description = "LocalSend CLI (official)";
    homepage = "https://github.com/localsend/localsend";
    license = lib.licenses.asl20;
    mainProgram = "localsend-cli";
  };
}
