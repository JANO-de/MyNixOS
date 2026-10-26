# Everything every host needs regardless of hardware or desktop:
# boot, nix, user, locale, fonts, shell, zram, Home Manager wiring.
{ pkgs, lib, inputs, theme, ... }:

{
  # --- boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- nix ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # --- user ---
  users.users.jano = {
    isNormalUser = true;
    description = "jano";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    autoSubUidGidRange = false;
    subUidRanges = [ { startUid = 100000; count = 100000; } ];
    subGidRanges = [ { startGid = 100000; count = 100000; } ];
  };

  # --- locale ---
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = builtins.listToAttrs (map
    (n: { name = "LC_${n}"; value = "es_ES.UTF-8"; })
    [ "ADDRESS" "IDENTIFICATION" "MEASUREMENT" "MONETARY" "NAME" "NUMERIC" "PAPER" "TELEPHONE" "TIME" ]);
  console.keyMap = "es";

  # --- fonts ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    dm-mono
    material-symbols
  ];

  # --- misc base ---
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # zram: compressed in-memory swap. RAM-backed, so the effective ceiling is
  # about your RAM size. The Surface overrides this (8 GB machine).
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    memoryMax = 17179869184; # 16 GiB
    algorithm = "zstd";
    priority = 100;
  };

  # --- shell ---
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "web-search" "copyfile" "dirhistory" ];
    };
    promptInit = lib.mkForce "eval \"$(starship init zsh)\"";
    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza --icons --group-directories-first -la";
      tree = "eza --icons --tree";
      cat = "bat";
      grep = "rg";
      find = "fd";
      ps = "procs";
      zz = "z";
      vim = "nvim";
      g = "git";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      ff = "fastfetch";
    };
  };
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # --- Home Manager wiring (per-user config lives in ./home.nix) ---
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs theme; };
    users.jano = import ./home.nix;
  };
}
