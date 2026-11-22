# Vikunja: self-hosted to-do app, served on http://todo.home.arpa via caddy-lan.nix.
# Homepage has no built-in to-do widget, so Homepage links to this app instead.
# SQLite by default, data in /var/lib/vikunja (worth adding to the restic paths).
{ ... }:
{
  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "todo.home.arpa";
    port = 3456;
  };
}
