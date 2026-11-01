# Explicit import list of every feature. No auto-import magic.
# Deleting a feature = deleting its folder + one line here.
{ ... }@args:
{
  imports = [
    ./services-extras
    ./nvidia
    ./orchard
    ./nixscout
    ./droidloom
    ./programs
    ./dotfiles
    ./hyprland-session
    ./greeter
    ./immaterial
    ./halo
    ./dynisland
    ./chronos
  ];
}
