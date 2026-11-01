# Shell (zsh + starship) and base programs.
{ pkgs, lib, ... }:

{
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

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
       qsdev = "nohup qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml >/tmp/ii-shell.log 2>&1 &";
       qsrestart = "pkill -f shell.qml; sleep 1; nohup qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml >/tmp/ii-shell.log 2>&1 &";
       qsdevlog = "qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml 2>&1 | tee /tmp/ii-shell.log";
       qsstop = "pkill -f shell.qml";
     };
  };
  environment.shellAliases = {
    qsdev = "nohup qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml >/tmp/ii-shell.log 2>&1 &";
    qsrestart = "pkill -f shell.qml; sleep 1; nohup qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml >/tmp/ii-shell.log 2>&1 &";
    qsdevlog = "qs -p ~/Proyectos/ii-halos/dots/.config/quickshell/ii/shell.qml 2>&1 | tee /tmp/ii-shell.log";
    qsstop = "pkill -f shell.qml";
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
