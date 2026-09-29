#!/usr/bin/env python3
"""Register the Monitor Manager page in iNiR's SettingsPageRegistry.qml.

The settings page list is a hard-coded array in the upstream shell, so a page
added outside iNiR has to be spliced in at build time. Every edit is anchored to
an exact expected string and aborts the build when the anchor is missing, so an
upstream iNiR update fails loudly instead of shipping a settings window with a
silently missing page.

The new page's index is derived from the current length of the array instead of
being hard-coded, so the sidebar category and the search index cannot drift away
from the position the page actually ends up in.

Usage: patch-inir-registry.py <SettingsPageRegistry.qml>
"""

import re
import sys
from pathlib import Path

PAGE_KEY = "monitor-manager"
PAGE_COMPONENT = "monitor-manager-settings/MonitorManagerConfig.qml"

PAGES_ANCHOR = """            component: "modules/settings/IrisConfig.qml"
        }
    ]
"""

PAGES_REPLACEMENT = """            component: "modules/settings/IrisConfig.qml"
        },
        {
            key: "monitor-manager",
            name: Translation.tr("Monitor Manager"),
            icon: "display_settings",
            desc: Translation.tr("Rearrange, rescale, profiles"),
            essential: false,
            component: "@COMPONENT@"
        }
    ]
"""


CATEGORY_ANCHOR = '{ label: Translation.tr("System"), pages: [1, 24, 7, 6, 12, 15, 8, 17] }'
CATEGORY_REPLACEMENT = (
    '{ label: Translation.tr("System"), pages: [1, 24, 7, 6, 12, 15, 8, 17, @INDEX@] }'
)

SEARCH_ANCHOR = """        const manualIndex = [
"""

SEARCH_REPLACEMENT = """        const manualIndex = [
        {
            pageIndex: @INDEX@, pageName: root.pages[@INDEX@].name,
            section: Translation.tr("Monitor Manager"),
            label: Translation.tr("Rearrange monitors"),
            description: Translation.tr("Drag screens into place, change resolution, refresh rate and scale"),
            keywords: ["monitor", "display", "screen", "rearrange", "drag", "layout", "resolution", "refresh", "hz", "scale", "zoom", "niri", "multi"]
        },
        {
            pageIndex: @INDEX@, pageName: root.pages[@INDEX@].name,
            section: Translation.tr("Monitor Manager"),
            label: Translation.tr("Monitor configurations"),
            description: Translation.tr("Save the current screen arrangement as a named profile and load it back"),
            keywords: ["monitor", "profile", "configuration", "preset", "scenario", "save", "load", "school", "home", "layout"]
        },
"""

PAGES_START = re.compile(r"^\s*readonly property var pages: \[$")
# Entries are indented by 12 spaces inside the pages array.
PAGE_ENTRY = re.compile(r'^ {12}key: "')


def count_pages(content: str, path: Path) -> int:
    """Number of entries in the pages array, i.e. the index the new page gets."""
    lines = content.splitlines()
    start = next((i for i, line in enumerate(lines) if PAGES_START.match(line)), None)
    if start is None:
        print(
            f"monitor-manager: no 'readonly property var pages' array in {path}; "
            f"the iNiR version changed; update this patch.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    count = 0
    for line in lines[start + 1:]:
        if PAGE_ENTRY.match(line):
            count += 1
        elif line == "    ]":
            return count
        elif line.startswith("    ]"):
            return count

    print(
        f"monitor-manager: could not find the end of the pages array in {path}; "
        f"the iNiR version changed; update this patch.",
        file=sys.stderr,
    )
    raise SystemExit(1)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    content = path.read_text()

    if PAGE_COMPONENT in content:
        print(f"monitor-manager: already registered in {path}")
        return 0

    index = count_pages(content, path)
    # Plain token substitution: the replacements are QML object literals full of
    # braces, so str.format would choke on them.
    edits = (
        ("pages array", PAGES_ANCHOR, PAGES_REPLACEMENT),
        ("sidebar category", CATEGORY_ANCHOR, CATEGORY_REPLACEMENT),
        ("search index", SEARCH_ANCHOR, SEARCH_REPLACEMENT),
    )

    for label, anchor, replacement in edits:
        occurrences = content.count(anchor)
        if occurrences != 1:
            print(
                f"monitor-manager: cannot patch {label}: expected exactly one "
                f"anchor in {path}, found {occurrences}. The iNiR version "
                f"changed; update this patch.",
                file=sys.stderr,
            )
            return 1
        content = content.replace(
            anchor,
            replacement.replace("@INDEX@", str(index)).replace("@COMPONENT@", PAGE_COMPONENT),
        )

    path.write_text(content)
    print(f"monitor-manager: registered settings page {index} in {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
