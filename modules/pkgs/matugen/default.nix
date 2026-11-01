{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "matugen";
  version = "4.1.0";

  src = fetchFromGitHub {
    owner = "InioX";
    repo = "matugen";
    rev = "v${version}";
    hash = "sha256-xzwMDWb6pF3oStVoS8enNhpYptxdnB1NSIO7dUH6/qk=";
  };

  cargoHash = "sha256-bfvlPiTlPQeedo+ikHXSI8NqdA5R5M7gCsgx7srYsMQ=";

  meta = {
    description = "Material you color generation tool";
    homepage = "https://github.com/InioX/matugen";
    license = lib.licenses.gpl2Plus;
    mainProgram = "matugen";
  };
}
