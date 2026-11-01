# DynIsland plugin contract (minimal)

A plugin lives in `modules/plugins/<id>/` and exposes:
- `Plugin.qml`: root `Item` with required properties:
  - `pluginId: string`
  - `pluginName: string`
  - `pluginEnabled: bool` (bind to Config)
- Optional `SettingsPage.qml`: a Page component registered in Settings.
- Optional `islandComponent`: component to embed in Island (via Loader).

Registration:
- Add entry to `config/Config.qml` `plugins` list: `{ id, name, path, enabled }`.
- PluginHost (if present) loads enabled plugins via `Loader { source: path + "/Plugin.qml" }`.
- Settings auto-adds `SettingsPage.qml` if file exists.

IPC: plugins may call `dynisland ipc <target> <fn>` targets registered in their QML.

Status: contract only; host not yet implemented (T-1).
