{ config, pkgs, lib, ... }:

# PDF viewer. `zathura` in nixpkgs already wraps the mupdf + PS plugins, so
# long documents (papers, manuals) stay light on RAM.
{
  environment.systemPackages = lib.optionals config.modules.programs.reading.enable [ pkgs.zathura ];
}