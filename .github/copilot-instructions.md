# Copilot instructions for MyNixOS

This repository is a NixOS flake for three hosts: desktop, laptop, and surface. Keep changes narrow, host-aware, and consistent with the project’s documented state in [README.md](../README.md) and [HANDOFF.md](../HANDOFF.md).

## Project shape

- [flake.nix](../flake.nix): defines the shared flake inputs and the three `nixosConfigurations`.
- [hosts/desktop/default.nix](../hosts/desktop/default.nix): desktop host configuration.
- [hosts/laptop/default.nix](../hosts/laptop/default.nix): laptop host configuration.
- [hosts/surface/default.nix](../hosts/surface/default.nix): Surface-specific tablet configuration.
- [modules/core.nix](../modules/core.nix): common boot, nix, locale, shell, and Home Manager setup.
- [modules/hardware.nix](../modules/hardware.nix): BT, firmware, NVIDIA, disk-specific hardware quirks.
- [modules/services.nix](../modules/services.nix): networking, audio, printing, SSH, and optional extras.
- [modules/programs.nix](../modules/programs.nix): profile-based software selection (full vs lean).
- [modules/desktop](../modules/desktop): compositor and shell setup; desktop/laptop use mango + dynisland, Surface currently runs mango + dynisland as a tablet experiment unless explicitly reverted.

## Important constraints

- Keep mango on desktop and laptop by default, but the Surface is intentionally switched to a Mango tablet experiment for this configuration.
- Treat the Surface as a host-specific Mango override; keep it local to the Surface unless the setup is explicitly reverted to niri/chronos.
- Do not add the CachyOS kernel overlay to the Surface. The overlay is intentionally scoped to the laptop in [flake.nix](../flake.nix).
- Treat the host-specific quirks in [hosts/surface/default.nix](../hosts/surface/default.nix) as sensitive: IPTS, power management, wifi PMF/MTU, rfkill cleanup, and the touch-only login flow are all custom and intentionally tuned.
- Before any rebuild, follow the repo’s practice: `git add -A`, then rebuild the target host with `sudo nixos-rebuild switch --flake .#<host>`.

## Build and validation commands

Use the repo’s documented flake workflow:

```bash
git add -A
nix flake lock
sudo nixos-rebuild switch --flake .#desktop
# or
sudo nixos-rebuild switch --flake .#laptop
# or
sudo nixos-rebuild switch --flake .#surface
```

For quick repo-level checks when a local Nix toolchain is available:

```bash
nix flake show
nix eval .#nixosConfigurations.surface.config.system.build.toplevel.drvPath
```

## Repo conventions

- This is a NixOS flake configured around `nixosConfigurations`, not a standard app project. Prefer declarative, host-specific configuration changes over ad hoc shell scripts.
- Keep options and module wiring in the right layer: shared config goes in `modules/*.nix`, host-specific tweaks go in `hosts/<host>/default.nix`.
- Prefer the existing module pattern and naming (for example `modules.desktop`, `modules.services`, `modules.programs`).
- The project uses zsh with `grep` aliased to `rg` and `ls` aliased to `eza`; where needed, use explicit commands like `command ls` and `rg -g '*.nix'` to avoid shell alias surprises.

## Handoff notes to preserve

- The project already contains a handoff document with current decisions and open risks. Keep changes aligned with that document rather than inventing a new direction.
- If you are touching session or shell behavior, confirm whether the change applies to all hosts or only the Surface before making the edit.
- If a fix is only relevant to the Surface or the tablet flow, keep it local to [hosts/surface/default.nix](../hosts/surface/default.nix) or the relevant Surface module rather than broadening it to all hosts.

## Preferred workflow for AI changes

1. Start from the relevant host config and the nearest module.
2. Check the existing handoff and README notes before changing architecture or session choices.
3. Keep the diff minimal and focused on the root cause.
4. Preserve the repository’s host split unless the Surface is intentionally being used as a Mango tablet experiment:
   - desktop/laptop: mango + dynisland
   - surface: mango + dynisland (tablet experiment, local override)
5. Validate with the smallest relevant Nix rebuild or config evaluation possible.

## What not to do

- Do not silently broaden a Surface-specific workaround to the desktop or laptop.
- Do not change the host matrix or the flake inputs without clear reason.
- Do not duplicate project guidance already captured in [README.md](../README.md) and [HANDOFF.md](../HANDOFF.md).
- Do not assume untracked files are part of the flake; the repo’s workflow requires `git add -A` before rebuilds.

## Suggested next agent customizations

If you later want a more opinionated workflow, consider adding:

- a host-specific instruction set for the Surface tablet quirks
- a shell/session update checklist for compositor and quirk tuning
- a Nix validation prompt for flake changes and rebuild safety

These should remain secondary to the repo’s current source of truth: [README.md](../README.md), [HANDOFF.md](../HANDOFF.md), and the host/module configs in this repository.
