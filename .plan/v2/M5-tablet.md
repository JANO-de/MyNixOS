# M5: ii tablet fork & strip plan (halos1)

Goal: make ii run smoothly on 4GB Surface (tablet mode). Two paths.

## Path A: Strip ii config (fast)
- Disable heavy widgets, blur, animations in config.json.
- Remove unused services (kdeconnect, lyrics, etc.) via config flags.
- Keep ii but minimal.

## Path B: Fork ii into a minimal tablet shell
- Clone ii-p3drovfx, remove desktop-only modules.
- Build a lightweight Quickshell config (bar + launcher + notifications).
- Package as a new flake package.

## Agent questions
1. Which path (strip vs fork)?
2. Which widgets to keep (bar, launcher, notifications, OSD)?
3. Accept reduced theming (no matugen) for performance?
4. Target RAM budget?
5. Keep touch/tablet gestures?

## Verification
- Boot halos1, measure RAM/CPU.
- Test touch, rotation, keyboard attach.
- Rollback via legacy-mango specialisation if needed.
