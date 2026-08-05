#!/usr/bin/env python3
"""Apply a hex-color mapping to Tide Island's theme sources.

Usage: patch-theme.py <mapping.json> <file> [<file>...]
The mapping is { old_hex: new_hex }; every occurrence of old_hex in each
file is replaced. Targets are the files that hardcode the UI colors
(Tide-island-app/Theme.qml and backend/StyleTokensBackend.cpp).
"""
import json
import sys


def main() -> None:
    mapping_file, *files = sys.argv[1:]
    with open(mapping_file, encoding="utf-8") as fh:
        mapping = json.load(fh)

    for path in files:
        with open(path, encoding="utf-8") as fh:
            content = fh.read()
        for old, new in mapping.items():
            content = content.replace(old, new)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(content)


if __name__ == "__main__":
    main()
