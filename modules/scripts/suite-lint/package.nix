# Runs from the repo checkout so the default apps_dir (modules/desktop/halo/src/apps) resolves.
{ pkgs, repoPath }:
pkgs.writeShellScriptBin "suite-lint" ''
  cd "${repoPath}"
  exec ${pkgs.python3}/bin/python3 ${./suite-lint.py} "$@"
''
