{ pkgs, inputs, self, ... }: {
  home.packages = with pkgs; [
    firefox
    librewolf
    kdePackages.kate
    foot              # Recommended terminal for Niri
    pavucontrol       # Audio control GUI
    libnotify         # Notifications
    nemo
    vscode
    vesktop
  ];
}
