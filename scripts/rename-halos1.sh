#!/usr/bin/env bash
# One-shot rename of the host "surface" -> "halos1" (roadmap A2). Safe to re-run.
# Keeps hardware names (microsoft-surface-pro-intel, libwacom-surface, surface-rotate,
# surface-button-bind, surface-pmf) and theme colours named "surface".
set -euo pipefail
cd "$(dirname "$0")/.."
git add -A

[ -d hosts/surface ] && git mv hosts/surface hosts/halos1

sed -i 's|surface = mkHost { host = "surface"; };|halos1 = mkHost { host = "halos1"; };|;
        s|desktop, laptop and surface|desktop, laptop and halos1|' flake.nix
sed -i 's|networking.hostName = "surface";|networking.hostName = "halos1";|;
        s|\.#surface|.#halos1|g; s|hosts/surface/|hosts/halos1/|g' hosts/halos1/default.nix
# stale header comment (lines 2-3: niri/chronos/SDDM) -> current stack
sed -i '2{/niri (chronos fork)/{N;s|.*|# Hyprland + Halo shell (greetd + cage greeter), lean program set. Deployed from the\n# desktop over SSH.|}}' hosts/halos1/default.nix
sed -i 's|hostName == "surface"|hostName == "halos1"|' modules/desktop/mango.nix
sed -i 's|see hosts/surface|see hosts/halos1|' modules/services.nix
sed -i 's|`desktop`, `laptop`, `surface`|`desktop`, `laptop`, `halos1`|;
        s|\.#surface|.#halos1|g; s|(surface)|(halos1)|; s/^| surface |/| halos1 |/' README.md

for n in clean deploy reboot; do
  [ -f "scripts/surface-$n.sh" ] && git mv "scripts/surface-$n.sh" "scripts/halos1-$n.sh"
done
[ -f scripts/ssh-config-surface.txt ] && git mv scripts/ssh-config-surface.txt scripts/ssh-config-halos1.txt
for f in scripts/*.sh scripts/ssh-config-halos1.txt; do
  [ "$(basename "$f")" = rename-halos1.sh ] && continue   # never edit this script itself
  sed -i 's|\.#surface|.#halos1|g; s|scripts/surface-|scripts/halos1-|g; s|\[surface-ip\]|[halos1-ip]|g; s|^Host surface$|Host halos1|' "$f"
done

# your local ssh alias (backup kept as config.bak-surface)
if [ -f "$HOME/.ssh/config" ] && grep -q '^Host surface$' "$HOME/.ssh/config"; then
  sed -i.bak-surface 's|^Host surface$|Host halos1|' "$HOME/.ssh/config"
fi

git add -A
echo "--- leftovers (expected: hardware names, theme colours, surface-rotate):"
git grep -n 'surface' -- flake.nix hosts scripts modules/desktop/mango.nix modules/services.nix README.md \
  | grep -viE 'microsoft-surface|libwacom-surface|linux-surface|surface-rotate|surface-button|surface-pmf|surface0|surface1|surface2' || true
echo "--- next: git diff --cached --stat; nix flake check --no-build; scripts/halos1-deploy.sh && scripts/halos1-reboot.sh"
