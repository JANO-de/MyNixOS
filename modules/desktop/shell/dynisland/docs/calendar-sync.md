# Calendar sync

Calendars show up in the island (right-click the date or week strip), the calendar widget
and the week-strip dots. Sources are managed in **Settings > Calendar**.

## 1. ICS link (easiest, read-only)
Paste a published `.ics` URL as an *ICS link* source.
- **Google**: Calendar settings > your calendar > *Integrate calendar* > **Secret address in iCal format**.
- **Outlook.com**: Settings > Calendar > Shared calendars > Publish (ICS link).
- **Proton**: calendar > Share > *Share with anyone* > copy link (ICS).
- **Nextcloud**: public share link with `?export` appended.

## 2. CalDAV through vdirsyncer (two-way servers, local copy)
vdirsyncer downloads any CalDAV server into a folder of `.ics` files; dynisland reads that folder.

`~/.config/vdirsyncer/config`:
```ini
[general]
status_path = "~/.local/share/vdirsyncer/status/"

[pair calendars]
a = "remote"
b = "local"
collections = ["from a", "from b"]
metadata = ["color", "displayname"]

[storage local]
type = "filesystem"
path = "~/.local/share/dynisland/calendars/"
fileext = ".ics"

[storage remote]
type = "caldav"
url = "https://cloud.example.com/remote.php/dav/"   # Nextcloud; iCloud: https://caldav.icloud.com/
username = "me"
password.fetch = ["command", "secret-tool", "lookup", "service", "my-caldav"]
```
Then once: `vdirsyncer discover calendars && vdirsyncer sync`.
In Settings > Calendar add a **Folder** source `~/.local/share/dynisland/calendars` and turn on
*Run vdirsyncer first* (it then syncs on every refresh).

**Google with OAuth** (instead of the secret link): use `type = "google_calendar"` for the remote storage
with `token_file`, `client_id`, `client_secret` (create them in Google Cloud Console), then `vdirsyncer discover`.

## 3. Tuta and other providers without CalDAV
Tuta offers no CalDAV/ICS feed. Export the calendar to an `.ics` file, put it in a folder and add that folder
as a *Folder* source (re-export to refresh).

## Limits
- Events with a `TZID` but no UTC time are read as local time (no timezone database in QML).
- Recurrence supported: DAILY, WEEKLY (BYDAY), MONTHLY (BYMONTHDAY, nth weekday), YEARLY, INTERVAL, COUNT, UNTIL, EXDATE, edited instances.
- Read-only: events can't be created or edited from the shell yet.
