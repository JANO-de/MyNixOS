# ytui (programs.ytui.enable): keyboard-driven TUI download manager for yt-dlp, from PyPI.
_: {
  flake.nixosModules.programs-ytui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.ytui;
      ytui = pkgs.python3Packages.buildPythonApplication rec {
        pname = "ytui-media";
        version = "0.1.5";
        pyproject = true;

        src = pkgs.python3Packages.fetchPypi {
          pname = "ytui_media";
          inherit version;
          hash = "sha256-VG8oKxchu4KEld9QmK3VIn8YVutYaGRI7TxHnM+4+BI=";
        };

        build-system = [ pkgs.python3Packages.setuptools ];
        dependencies = with pkgs.python3Packages; [
          textual
          rich
          yt-dlp
          mutagen
          arabic-reshaper
          python-bidi
        ];

        pythonRelaxDeps = true; # nixpkgs 26.05 may lag the pinned minimums
        doCheck = false;
        makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ pkgs.ffmpeg ]}" ];
        meta.mainProgram = "ytui";
      };
    in
    {
      options.programs.ytui = {
        enable = lib.mkEnableOption "ytui, TUI download manager for yt-dlp";
        package = lib.mkOption {
          type = lib.types.package;
          default = ytui;
          description = "The ytui package.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];
      };
    };
}
