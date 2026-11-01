# Explicit import list of every feature. No auto-import magic.
# Deleting a feature = deleting its folder + one line here.
{ ... }@args:
{
  imports = [
    ./hyprland-session
    ./greeter
    ./halo
    ./dynisland
    ./chronos
  ];
}
