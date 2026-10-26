# Programs, in two profiles:
#   "lean"  CLI essentials + zathura + moonlight + deskflow   (surface)
#   "full"  lean + apps, IDEs/languages, file manager, llama  (desktop, laptop)
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.programs;
  system = pkgs.stdenv.hostPlatform.system;
  full = cfg.profile == "full";
  llama = pkgs.llama-cpp.override { vulkanSupport = true; };
in
{
  options.modules.programs = {
    profile = lib.mkOption {
      type = lib.types.enum [ "full" "lean" ];
      default = "full";
      description = "Which program set this host gets. 'lean' is for low-RAM / small-disk machines (the Surface).";
    };

    deskflow = {
      role = lib.mkOption {
        type = lib.types.enum [ "none" "server" "client" ];
        default = "none";
        description = "Deskflow keyboard/mouse sharing: 'server' serves this host's input, 'client' consumes another server's, 'none' only installs the binary.";
      };
      serverAddress = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Host (name or IP) of the deskflow server, for role = 'client'.";
      };
    };
  };

  config = lib.mkMerge [
    # =====================================================================
    # Both profiles
    # =====================================================================
    {
      environment.systemPackages = with pkgs; [
        # terminal + CLI essentials
        neovim git wget curl jq
        alacritty starship fastfetch
        eza bat ripgrep fd procs zoxide z-lua
        atuin btop delta dust fzf ncdu tmux yq-go
        inputs.forge.packages.${system}.forge # Forge TUI for OpenCode

        # sharing one keyboard/mouse and streaming the screen
        deskflow
        moonlight-qt # on the Surface this renders a Sunshine server's screen

        # zathura: small keyboard-driven PDF viewer, pen-friendly. Plugin set
        # narrowed to the two PDF backends to keep the closure small.
        (zathura.override {
          plugins = with zathuraPkgs; [ zathura_pdf_mupdf zathura_pdf_poppler ];
        })
      ];

      systemd.user.services.deskflow-server = lib.mkIf (cfg.deskflow.role == "server") {
        description = "Deskflow keyboard/mouse server";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.deskflow}/bin/deskflow-server -f";
          Restart = "on-failure";
        };
      };

      systemd.user.services.deskflow-client = lib.mkIf (cfg.deskflow.role == "client") {
        description = "Deskflow keyboard/mouse client";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.deskflow}/bin/deskflow-client -f --address ${cfg.deskflow.serverAddress}";
          Restart = "on-failure";
        };
      };
    }

    # =====================================================================
    # Full profile
    # =====================================================================
    (lib.mkIf full {
      environment.systemPackages = with pkgs; [
        # --- apps ---
        inputs.zen-browser.packages.${system}.default
        vesktop
        bazaar # FlatHub-first app store
        inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
        inputs.opencode-flake.packages.${system}.opencode-avx

        # --- IDEs ---
        vscodium
        eclipses.eclipse-java
        jetbrains.idea
        netbeans

        # --- languages and tools the editors call ---
        jdk25 maven gradle
        gcc gdb clang-tools cmake ninja pkg-config
        python3 ruff uv
        nodejs_22
        nixd nixfmt direnv

        # --- local LLM (backs dynisland's AI panel, see llama-cpp below) ---
        llama

        # --- file manager (+ yazi previews: images, video, PDF, archives) ---
        nautilus
        yazi chafa ffmpegthumbnailer poppler-utils p7zip
      ];

      # Nautilus is the default file manager. gvfs is its backend for
      # removable drives and mounts.
      services.gvfs.enable = true;
      xdg.mime.defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
      };

      # Prebuilt binaries (VSCodium extensions, language servers...)
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
      };

      programs.forge.enable = true;
      environment.shellAliases.llm = "$HOME/.local/bin/llm";

      services.llama-cpp = {
        enable = true;
        package = llama;
        extraFlags = [ "--models-max" "1" ];

        modelsPreset = {
          "qwen3-8b" = {
            model = "/var/lib/llama-models/Qwen3-8B-Q4_K_M.gguf";
            alias = "qwen3-8b";
            ctx-size = "8192";
            fit-target = "640";
            temp = "0.6";
            top-p = "0.95";
            top-k = "20";
          };
          "qwen3-14b" = {
            model = "/var/lib/llama-models/Qwen3-14B-Q4_K_M.gguf";
            alias = "qwen3-14b";
            ctx-size = "8192";
            fit-target = "640";
            temp = "0.6";
            top-p = "0.95";
            top-k = "20";
          };
        };
      };
    })
  ];
}
