# The power button on the tablet: short press suspends (and the next press wakes
# it), long press asks whether to power off.
#
# Why not logind, which does know about press duration (HandlePowerKeyLongPress,
# systemd 256+): its action list is fixed and has no "suspend on short press but
# ignore the press that wakes", and no logind action can put a confirmation on
# screen before powering off.
#
# Why not keyd plus a GNOME custom keybinding, as modules/desktop/volume-keys.nix
# does for the volume buttons: keyd rewrites the key but has no notion of how
# long it was held, and a custom keybinding fires on press-down, so it cannot
# tell a tap from a hold. Distinguishing them needs the raw press/release pair,
# so this reads the input node itself.
#
# Why the node is read *without* EVIOCGRAB: a grab would also hide the key from
# mutter, and mutter is what turns the panel back on when the button is pressed
# while the screen is black. So the other consumers are told to ignore the key
# instead -- gsd-power via power-button-action='nothing' below, logind via
# HandlePowerKey="ignore" in hosts/surface/hardware.nix -- and keyd does not
# map it at all.
#
# Suspending needs no session, so the daemon does it itself on the system bus.
# Only the power-off prompt needs the desktop session, so that half is run as the
# logged-in user; with nobody logged in a long press only logs a line.
#
# The sleep key is remapped away: a tablet carried in a bag must not suspend by
# accident.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.powerButton;

  # The session-scoped half. Suspending is not here because it needs no session;
  # only the confirmation dialog does, since it has to be drawn on the desktop.
  action = pkgs.writeShellApplication {
    name = "power-button-action";
    runtimeInputs = [
      pkgs.systemd
      pkgs.yad
    ];
    text = ''
      case "''${1:-}" in
        poweroff)
          # yad exits with the id of the button that was pressed, so only a
          # deliberate "Shut down" reaches systemctl; Cancel and the 60s
          # timeout both fall through.
          if yad --timeout=60 \
            --text="Power off the tablet?" \
            --window-icon=system-shutdown \
            --width=320 \
            --button="Shut down:0" \
            --button="Cancel:1"; then
            systemctl poweroff
          fi
          ;;
        *)
          echo "usage: power-button-action poweroff" >&2
          exit 2
          ;;
      esac
    '';
  };

  daemonSource = ''
    #!${pkgs.python3}/bin/python3
    import os
    import re
    import select
    import struct
    import subprocess
    import sys
    import time

    KEY_POWER = 116
    WORD_BITS = 64
    EV_KEY = 0x01
    EV_RELEASED = 0
    EV_PRESSED = 1
    EVENT_FORMAT = "llHhi"
    ACTION = "${action}/bin/power-button-action"
    LOGIND = "${pkgs.systemd}/bin/loginctl"
    SYSTEMCTL = "${pkgs.systemd}/bin/systemctl"
    RUNUSER = "${pkgs.util-linux}/bin/runuser"
    ENV = "${pkgs.coreutils}/bin/env"
    # Milliseconds as an int, then divided once, so the threshold is exact rather
    # than a float that 800/1000 would introduce.
    LONG_PRESS_MS = ${toString cfg.longPressMs}
    LONG_PRESS = LONG_PRESS_MS / 1000.0

    def log(message):
        print("power-button: " + message, flush=True)

    def selftest():
        """Sanity checks that need no input device, so a broken build fails here."""
        print("power-button: selftest: nodes " + str(power_nodes()))
        # The kernel bitmap parser is the part most likely to rot, so check the
        # two encodings it has to get right: a single bit in one word, and two
        # bits in the following word (event6's volume keys).
        cases = {
            "10000000000000 0": [116],
            "c000000000000 0": [114, 115],
        }
        for text, expected in cases.items():
            got = key_codes(text)
            if got != expected:
                raise SystemExit(
                    "power-button: selftest: parsed " + str(got)
                    + " from " + text + ", expected " + str(expected))
        print("power-button: selftest: bitmap parsing ok")
        print("power-button: selftest: long press threshold "
              + str(LONG_PRESS_MS) + "ms")
        print("power-button: selftest: ok")

    def key_codes(bitmap):
        """Key codes set in one "B: KEY=" value from /proc/bus/input/devices.

        The kernel prints these bitmaps as %lx words with no zero padding, most
        significant word first, and stops after the last non-zero word. Counting
        from the right, word n covers key codes 64n..64n+63.
        """
        codes = []
        for index, word in enumerate(reversed(bitmap.split())):
            value = int(word, 16)
            for bit in range(WORD_BITS):
                if (value >> bit) & 1:
                    codes.append(WORD_BITS * index + bit)
        return codes

    def session_property(session_id, name):
        result = subprocess.run(
            [LOGIND, "show-session", session_id, "-p", name, "--value"],
            capture_output=True, text=True,
        )
        return result.stdout.strip()

    def session():
        """(user, uid) of the session that can show the dialog, or None.

        A user session is preferred over the greeter so the prompt appears over
        the desktop rather than over the login screen.
        """
        result = subprocess.run(
            [LOGIND, "list-sessions", "--no-legend"],
            capture_output=True, text=True,
        )
        candidates = []
        for line in result.stdout.splitlines():
            fields = line.split()
            if len(fields) > 2 and fields[2] in ("user", "greeter"):
                candidates.append(fields)

        for fields in sorted(candidates, key=lambda entry: entry[2] != "user"):
            uid = session_property(fields[0], "UID")
            if not uid.isdigit():
                continue
            return session_property(fields[0], "Name") or "root", int(uid)
        return None

    def run_in_session(argv):
        target = session()
        if target is None:
            log("no session to draw on; ignoring " + argv[1])
            return
        user, uid = target
        runtime = "/run/user/" + str(uid)
        # runuser without --login does not need a shell for the target user, and
        # the environment is passed explicitly so it survives runuser's own
        # idea of what a login environment looks like.
        subprocess.run([
            RUNUSER, "-u", user, "--", ENV,
            "XDG_RUNTIME_DIR=" + runtime,
            "DBUS_SESSION_BUS_ADDRESS=unix:path=" + runtime + "/bus",
            "XDG_SESSION_TYPE=wayland",
            "WAYLAND_DISPLAY=wayland-0",
            ACTION,
        ] + argv[1:])

    def power_nodes():
        """Every input node reporting KEY_POWER as [(name, path)].

        keyd may already own the raw node and re-emit the key on its own virtual
        keyboard, so all matching nodes are read and presses are de-duplicated.
        """
        found = []
        try:
            with open("/proc/bus/input/devices") as handle:
                blocks = handle.read().strip().split("\n\n")
        except OSError as error:
            log("cannot read /proc/bus/input/devices: " + str(error))
            return found
        for block in blocks:
            name = re.search(r'N: Name="([^"]+)"', block)
            handlers = re.search(r"H: Handlers=(.*)", block)
            bitmap = re.search(r"B: KEY=(.*)", block)
            if not (name and handlers and bitmap):
                continue
            if KEY_POWER not in key_codes(bitmap.group(1)):
                continue
            for node in handlers.group(1).split():
                if node.startswith("event"):
                    found.append((name.group(1), "/dev/input/" + node))
        return found

    def suspend():
        subprocess.run([SYSTEMCTL, "suspend"])

    def watch():
        size = struct.calcsize(EVENT_FORMAT)
        while True:
            fds = {}
            for name, path in power_nodes():
                try:
                    fds[os.open(path, os.O_RDONLY)] = path
                except OSError as error:
                    log("cannot open " + path + ": " + str(error))
            if not fds:
                log("no node reports KEY_POWER; retrying")
                time.sleep(5)
                continue

            log("watching " + ", ".join(fds.values()))
            pressed = {}
            last_action = 0.0
            alive = True
            while alive:
                ready, _, _ = select.select(list(fds), [], [])
                for fd in ready:
                    try:
                        data = os.read(fd, size)
                    except OSError:
                        alive = False
                        break
                    if len(data) < size:
                        alive = False
                        break
                    _, _, kind, code, value = struct.unpack(EVENT_FORMAT, data)
                    if kind != EV_KEY or code != KEY_POWER:
                        continue
                    if value == EV_PRESSED:
                        pressed[fd] = time.monotonic()
                    elif value == EV_RELEASED and fd in pressed:
                        now = time.monotonic()
                        held = now - pressed.pop(fd)
                        # Same press seen on two nodes (raw + keyd): act once.
                        if now - last_action < 1.0:
                            continue
                        last_action = now
                        is_long = held >= LONG_PRESS
                        log(("long press" if is_long else "short press")
                            + " after " + ("%.2f" % held) + "s")
                        if is_long:
                            run_in_session([ACTION, "poweroff"])
                        else:
                            suspend()

            for fd in fds:
                os.close(fd)
            log("node went away; re-resolving")
            time.sleep(1)

    if "--selftest" in sys.argv:
        selftest()
    else:
        watch()
  '';

  # writeTextFile rather than runCommand + replaceVars: the whole script is
  # Python with a fixed shebang, so it only needs the executable bit, and the
  # store paths are interpolated directly. Nix ${...} inside the script has to
  # be written as ''${...} (see ACTION/LOGIND below).
  daemon = pkgs.writeTextFile {
    name = "power-button-daemon";
    destination = "/bin/power-button";
    executable = true;
    checkPhase = ''
      runHook preCheck
      "$target" --selftest
      runHook postCheck
    '';
    text = daemonSource;
  };
in
{
  # Options are declared in modules/desktop/options.nix with the rest of the
  # desktop options; this module only implements them.
  config = lib.mkIf (cfg.enable && config.modules.desktop.gnome.enable) {
    # The button is grabbed by the daemon below, so the shell no longer sees it.
    # This is belt and braces for the window between login and the daemon's
    # first grab, and it keeps a dead button dead rather than surprising.
    programs.dconf.profiles.user.databases = [
      {
        settings."org/gnome/settings-daemon/plugins/power".power-button-action = "'nothing'";
      }
    ];

    # The sleep key is still remapped away: a tablet carried in a bag should not
    # suspend by accident. The power key is deliberately absent -- the daemon
    # owns it, and keyd must not emit F13 for a key nobody is listening to.
    services.keyd = {
      enable = true;
      keyboards.tablet.settings.main.sleep = "f14";
    };

    systemd.services.power-button = {
      description = "Power button: short press blanks or wakes, long press offers power off";
      wantedBy = [ "multi-user.target" ];
      # surface-button-bind re-probes soc_button_array at boot, which is what
      # creates the node carrying KEY_POWER in the first place.
      after = [ "surface-button-bind.service" ];
      wants = [ "surface-button-bind.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${daemon}/bin/power-button";
        Restart = "always";
        RestartSec = 2;
      };
    };
  };
}
