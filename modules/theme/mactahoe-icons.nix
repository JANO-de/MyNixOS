{ stdenvNoCC, fetchFromGitHub, gtk3 }:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-icon-theme";
  version = "git-839848b9a8a38a92a6936e30c4abe35cc6f2546d";
  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "839848b9a8a38a92a6936e30c4abe35cc6f2546d";
    hash = "sha256-NAahlBOYub0QlqkYStamoCbyWh+H5JG/iFm4Ws9EU3A=";
  };
  nativeBuildInputs = [ gtk3 ];
  dontDropIconThemeCache = true;
  installPhase = ''
    runHook preInstall
    patchShebangs install.sh
    mkdir -p $out/share/icons
    ./install.sh -d $out/share/icons
    runHook postInstall
  '';
}
