# scripts/

One line per script (what, who runs it, where).

- `desktop-clear-oneshot.sh` — check and clear a stray `bootctl set-oneshot` on the desktop. Run on desktop.
- `halo-dev.sh` — hot-reload loop for the Halo shell (no rebuild/reboot). Run on dev machine.
- `halo-ipc.sh` — talk to the halo-test shell on the Surface (`scripts/halo-ipc.sh call shade toggle`). Run on dev machine.
- `halo-live-binds.sh` — reset binds and add the top-edge shade bind. Run on dev machine.
- `halos1-android-apps.sh` — install F-Droid/Aurora/microG into Droidloom on halos1. Run on PC, targets halos1.
- `halos1-baseline.sh` — battery baseline measurement on halos1. Run on halos1 on battery.
- `halos1-clean.sh` — drop old Surface generations, rewrite boot menu. Run on halos1.
- `halos1-deploy.sh` — rebuild the Surface from this machine. Run on dev machine.
- `halos1-reboot.sh` — reboot the Surface. Run on dev machine.
- `rename-halos1.sh` — one-shot rename "surface" -> "halos1" (roadmap A2). Run once.
- `suite-lint.py` — lint the Halo suite QML apps.
