# Builds one command from a script file. The command runs from the repo checkout:
# $MYNIXOS_REPO is set to repoPath before the script body.
{ pkgs, repoPath }:
{
  name,
  src,
  inputs ? [ ],
}:
pkgs.writeShellScriptBin name ''
  export MYNIXOS_REPO="${repoPath}"
  ${pkgs.lib.optionalString (inputs != [ ]) ''export PATH="${pkgs.lib.makeBinPath inputs}:$PATH"''}
  ${builtins.readFile src}
''
