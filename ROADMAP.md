# HALOS1 Roadmap v1.1

Date: 2026-10-26. Next update number: 63 (61 = roadmap + HANDOFF sync, 62 = rename script A2).

## Decisions (user)
- Update 60 is applied; numbering continues at 61.
- Settings follows **AOSP main** (port 1:1, cite files). Light theme **toggleable** (dark stays default).
- Android apps installed with **F-Droid and Aurora Store**.
- Clock, Calculator, Weather, Notes: **Halo-native**.
- Performance = **battery life**.
- Android runtime when idle: **as small as possible**, only enough for notifications and basic backend services.
- Rename everything to **halos1** at once, no `surface` ssh alias.

## Baseline
| Area | State |
| --- | --- |
| Shell (dock, split, Manage windows, widgets, folders, back gesture), Files v2, Settings window, greeter, Plymouth ring | Confirmed |
| Droidloom (Android apps in Wayland windows) | Apps run; Intel rendering, RAM, disk not measured |
| Gallery rewrite (38) | Never seen in a log |
| Hyprland crash report | Never read |
| HANDOFF / README / host comment | Drift: fixed for HANDOFF in 61; README and host comment still stale |
| Shell memory | 420-530 MB peak per run |
| Device memory (measured 62) | `free -m` total 3832 MB, 2730 used, 1102 available; disk 117 G, 66 G free. Host comment says 8 GB: confirm the model |

## Tracks
Size: S = one update, M = 2-4, L = 5+.

| ID | Item | Size | Needs |
| --- | --- | --- | --- |
| A1 | Sync HANDOFF (done in 61); refresh README and host comment | S | none |
| A2 | **Shipped in 62 (awaiting deploy test).** Rename to halos1: `hosts/surface` -> `hosts/halos1`, `flake.nix` line 99 `surface = mkHost`, line 2 description, `networking.hostName` (default.nix:54), `surface-*.sh` scripts, ssh config, `mango.nix` check. Hardware names (`microsoft-surface-pro-intel`, `libwacom-surface`, `surface-button-bind`, `00-surface-pmf.conf`) stay | M | grep of scripts, ssh config, mango.nix |
| A3 | Droidloom acceptance: Intel rendering, idle RAM, disk, app ids in Hyprland | S | none |
| A4 | Hyprland crash report | S | the report |
| A5 | Gallery log, fix what fails | S | the log |
| A6 | One-tap rollback (polkit) in Settings | M | B4 |
| B1 | Read AOSP main Settings: category order, structure, strings, dimens | M | none |
| B2 | Component kit: collapsing large title, preference row, group card, switch/slider/dropdown/radio, search field; theme tokens with light + dark | M | B1 |
| B3 | Two-pane layout + Android-order top list | M | B2 |
| B4 | Migrate the 12 pages (Wi-Fi, Bluetooth, Display, Sound, Battery first) | L | B3 |
| B5 | Settings search | M | B4 |
| B6 | New pages: Notifications per app, Accessibility, Storage, Android apps, Wallpaper & style (incl. light/dark toggle), Battery | L | B4 |
| C1 | Android apps in Library, Home, dock with Halo-themed icons | M | A3 |
| C2 | Runtime lifecycle: minimal idle profile (notifications + backend only), full start on first app launch | M | A3, F1 |
| C3 | Split, Manage windows, back gesture as Android Back | M | C1 |
| C4 | Shared folder instead of `share_user_folders`; clipboard | M | A3 |
| C5 | Android notifications into Halo notification centre | L | C1, C2 |
| C6 | F-Droid + Aurora Store install path (Settings page); Droidloom version bump script | M | B6 |
| D1 | Clock (+ widget) | M | none |
| D2 | Notes, Calculator, Weather | L | D1 |
| D3 | Calendar, Reminders, Contacts | L | D1 |
| E1 | Greeter-to-desktop black gap | M | none |
| E2 | Lock screen widgets, idle lock timeout | M | none |
| E3 | Stage Manager-style groups, Spotlight pull-down search | L | C3 |
| E4 | Clipboard panel (cliphist), notification grouping/reply | M | none |
| F1 | Battery baseline script: idle drain, wakeups and CPU per process (quickshell, Hyprland, droidloomd), RAM | S | none |
| F2 | Replace polling with events (`halo-split` 1 s, lsblk 4 s, `WidgetData` 2 s, per-screen duplicates) | M | F1 |
| F3 | Battery tuning: powertop/TLP-style settings, screen timeout and dim, suspend/S0ix, zram, Android cgroup limits | M | F1, C2 |

## Order
| Phase | Items | Gate |
| --- | --- | --- |
| P0 Sync and measure | A1, A3, A4, A5, F1 | HANDOFF matches source; idle battery/RAM numbers recorded; crash report and Gallery log read |
| P1 Rename | A2 | `.#halos1` boots; ssh and deploy scripts work; old generation selectable |
| P2 Settings kit | B1, B2, B3 | Two-pane list in Halo style, Wi-Fi migrated, light/dark switch works |
| P3 Android core | C1, C2, C4 | Android apps launch from Library and dock; idle runtime minimal; files via one folder |
| P4 Settings pages | B4, B5, B6, A6 | 12 pages migrated, search works, rollback in one tap |
| P5 Android depth | C3, C5, C6, F2, F3 | Split and Back work; notifications arrive with runtime idle; F-Droid/Aurora install works; battery gain measured vs F1 |
| P6 Suite and polish | D1-D3, E1-E4 | Halo-native suite with widgets; black gap gone |

## Settings revamp (port from AOSP main)
Keep Android's structure, order, wording and behaviour; draw with Halo tokens, line icons, radii.
- Home: search pill, suggestions card, category list with icon badges and one-line summaries.
- Large collapsing title on every page.
- Preference groups as rounded cards; switch/slider/dropdown/radio rows (`SetGroup`/`SetRow` rebuilt as the kit).
- Two-pane at 900 px or wider, animated page swap.
- Order: Network & internet, Connected devices, Apps, Notifications, Battery, Storage, Sound, Display, Wallpaper & style, Accessibility, Security & privacy, Location, System, About (drop SIM/NFC/emergency). Verified against AOSP in B1.
- Halo-only rows stay: home and dock options, Android apps (Droidloom), split and window behaviour.
- Light and dark: new theme tokens, toggle in Wallpaper & style.

## Open
- A2: run `scripts/rename-halos1.sh`, deploy, reboot, report.
- A3, A4, A5 need the Surface outputs/logs listed in HANDOFF section 0c.
