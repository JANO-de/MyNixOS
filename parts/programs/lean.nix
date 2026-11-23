# Lean profile: CLI essentials + ffmpeg/yt-dlp + zathura + deskflow (all hosts).
_: {
  flake.nixosModules.programs-lean =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:

    let
      system = pkgs.stdenv.hostPlatform.system;
      cfg = config.modules.programs;
    in
    lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        neovim
        gcc
        tree-sitter
        nodejs
        nil
        lua-language-server
        nixfmt
        stylua
        vtsls
        tailwindcss-language-server
        vscode-langservers-extracted
        yaml-language-server
        taplo
        marksman
        prettierd
        bash-language-server
        shellcheck
        shfmt
        statix
        deadnix
        lazygit
        git
        wget
        curl
        jq
        alacritty
        starship
        fastfetch
        eza
        bat
        ripgrep
        fd
        procs
        zoxide
        z-lua
        atuin
        btop
        delta
        dust
        fzf
        ncdu
        tmux
        yq-go

        # network + system CLI basics
        bind.dnsutils # dig, nslookup, host
        whois
        nmap
        rsync
        lsof
        psmisc # killall, fuser, pstree
        pciutils # lspci
        usbutils # lsusb
        file
        inputs.forge.packages.${system}.forge
        appimage-run
        ffmpeg
        yt-dlp

        deskflow

        (zathura.override {
          plugins = with zathuraPkgs; [
            zathura_pdf_mupdf
            zathura_pdf_poppler
          ];
        })
      ];
    };
}
