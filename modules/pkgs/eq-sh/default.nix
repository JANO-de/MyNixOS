{ lib, pkgs }:
pkgs.python3Packages.buildPythonPackage rec {
  pname = "aureli";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "eq-desktop";
    repo = "cli";
    rev = "v${version}";
    hash = "1xqm4am5narw2hzmcww528galiv5lxngjcbc785zslc2zp5nx1xi";
  };

  pyproject = true;

  meta = {
    description = "Aureli CLI (au)";
    homepage = "https://github.com/eq-desktop/cli";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tysonz ];
    programs = with pkgs; {
      au = "au";
    };
  };
}