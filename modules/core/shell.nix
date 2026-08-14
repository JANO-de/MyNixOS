{ config, pkgs, lib, ... }:

{
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
      nv = "neovide";
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
}


