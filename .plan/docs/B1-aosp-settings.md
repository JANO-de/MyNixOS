# B1: AOSP Settings reference (started 2026-10-26)

Source read: platform/packages/apps/Settings `res/xml/top_level_settings.xml` at commit f3848729b416 (older than aosp-main; re-check against main).
Top-level order (`android:order`): network -120, connected_devices -110, apps_and_notifs -100, battery -90, display -80, sound -70, storage -60, privacy -55, location -50, security -40, accounts -30, accessibility -20, system 10, about_device 20, support 100.
Main (per ROADMAP): Network & internet, Connected devices, Apps, Notifications, Battery, Storage, Sound, Display, Wallpaper & style, Accessibility, Security & privacy, Location, System, About.
Halo mapping: wifi=Network & internet, bluetooth=Connected devices, home=Home screen, updates=System updates.
Patterns/components: `res/values/styles_preference.xml` (preference layout, dividers), `Theme.DeviceDefault.Settings` (ActionBar).
TODO (B1 remainder): dimens (row height, padding, icon size), strings, collapsing large title, two-pane weights (`layout-sw600dp/settings_top_level.xml` uses weight .4, margin 10dp).
