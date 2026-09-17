#!/usr/bin/env python3
"""Enforces "the KIDS colors must be exposed as reusable design tokens...
do not hard-code these colors repeatedly in individual components": the
four brand hex codes may only appear inside Theme.qml (their one
definition) and branding/ (SVG/color-scheme brand assets, which are
allowed to be literal). Any other .qml/.cpp file referencing one of these
hexes directly, instead of via Theme.logo.*/Theme.KIDS_*, is a violation.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

BRAND_HEXES = ["#FF5A5F", "#FFB400", "#00C2A8", "#3D8BFD"]
ALLOWED_DIRS = ["branding"]
ALLOWED_FILES = ["branding/themes/qml/Theme.qml"]
SCAN_EXTENSIONS = {".qml", ".cpp", ".h"}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")


def main() -> None:
    violations = []

    for path in ROOT.rglob("*"):
        if path.suffix not in SCAN_EXTENSIONS:
            continue
        if ".git" in path.parts:
            continue
        rel = path.relative_to(ROOT).as_posix()
        if any(rel.startswith(d + "/") for d in ALLOWED_DIRS):
            continue
        if rel in ALLOWED_FILES:
            continue

        text = path.read_text(encoding="utf-8")
        for hexcode in BRAND_HEXES:
            for match in re.finditer(re.escape(hexcode), text, re.IGNORECASE):
                line_no = text.count("\n", 0, match.start()) + 1
                violations.append(f"{rel}:{line_no} hard-codes {hexcode} — use Theme.logo.*/Theme.KIDS_* instead")

    if violations:
        for v in violations:
            fail(v)
        sys.exit(1)

    print("OK: KIDS brand colors are only defined in Theme.qml/branding/, "
          "never hard-coded in a component")


if __name__ == "__main__":
    main()
