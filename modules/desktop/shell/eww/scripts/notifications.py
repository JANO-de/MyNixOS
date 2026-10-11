#!/usr/bin/env python3
"""Minimal org.freedesktop.Notifications server that feeds the eww island.

It owns the notification bus name and prints the whole current notification
list as a single JSON line on every change. An eww `deflisten` consumes that
stream and renders the popups; closing a popup calls CloseNotification back on
this server, which keeps the list in sync.

Runs with the python environment provided by modules/desktop/shell/eww.nix
(python3 + dbus-next).
"""

import asyncio
import json
import os
import sys

from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, signal


def bus_address():
    addr = os.environ.get("DBUS_SESSION_BUS_ADDRESS")
    if addr:
        return addr
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    return f"unix:path={runtime}/bus"


class Notifications(ServiceInterface):
    def __init__(self):
        super().__init__("org.freedesktop.Notifications")
        self.notifications = []
        self.next_id = 1
        self.timers = {}

    def broadcast(self):
        sys.stdout.write(json.dumps(self.notifications, ensure_ascii=False) + "\n")
        sys.stdout.flush()

    def drop(self, nid, reason=2):
        if not any(n["id"] == nid for n in self.notifications):
            return
        self.notifications = [n for n in self.notifications if n["id"] != nid]
        timer = self.timers.pop(nid, None)
        if timer is not None:
            timer.cancel()
        self.broadcast()
        try:
            self.NotificationClosed(nid, reason)
        except Exception:
            pass

    def expire(self, nid):
        self.drop(nid, reason=1)

    @method()
    def GetCapabilities(self) -> "as":
        return ["body", "body-markup", "actions", "persistence"]

    @method()
    def Notify(
        self,
        app_name: "s",
        replaces_id: "u",
        app_icon: "s",
        summary: "s",
        body: "s",
        actions: "as",
        hints: "a{sv}",
        expire_timeout: "i",
    ) -> "u":
        nid = replaces_id if replaces_id else self.next_id
        if not replaces_id:
            self.next_id += 1

        self.notifications = [n for n in self.notifications if n["id"] != nid]
        old = self.timers.pop(nid, None)
        if old is not None:
            old.cancel()

        self.notifications.insert(
            0,
            {
                "id": nid,
                "app": app_name or "",
                "summary": summary or "",
                "body": body or "",
                "icon": app_icon or "",
            },
        )
        self.broadcast()

        if expire_timeout != 0:
            timeout = expire_timeout if expire_timeout > 0 else 5000
            loop = asyncio.get_running_loop()
            self.timers[nid] = loop.call_later(timeout / 1000.0, self.expire, nid)
        return nid

    @method()
    def CloseNotification(self, nid: "u"):
        self.drop(nid, reason=3)

    @method()
    def GetServerInformation(self) -> "ssss":
        return ["eww-notifications", "MyNixOS", "0.1", "1.2"]

    @signal()
    def NotificationClosed(self, nid: "u", reason: "u") -> "uu":
        return [nid, reason]


async def main():
    bus = await MessageBus(bus_address=bus_address()).connect()
    iface = Notifications()
    bus.export("/org/freedesktop/Notifications", iface)
    await bus.request_name("org.freedesktop.Notifications")
    await bus.wait_for_disconnect()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
