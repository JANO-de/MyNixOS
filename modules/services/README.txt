1. Copy tracker.py and media-tracker.nix into modules/services/ (same folder).
2. In modules/services/default.nix add:   ./media-tracker.nix
3. In hosts/desktop/default.nix add:     modules.services.mediaTracker.enable = true;
4. Optional, keep your existing sheet:   cp server-tracker.xlsx /mnt/storage/tracker/
5. sudo nixos-rebuild switch --flake .#desktop
Check:  systemctl list-timers media-tracker ; journalctl -u media-tracker -f
Run now: sudo systemctl start media-tracker
