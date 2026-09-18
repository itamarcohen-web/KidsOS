#!/usr/bin/env python3
"""Exercises the actual Stage-1 rule table
(files/system/usr/lib/kidsos/models/text-safety/rules-0.1.json) against
the synthetic fixtures in tests/fixtures/safety/text/ (spec §41), using
the same "highest-weight regex match wins" logic
RuleBasedTextClassifier::AnalyzeText implements in C++
(files/apps/safety-agent/src/ai/RuleBasedTextClassifier.cpp) — this
can't run the real C++ code (no Qt/compiler here, see
docs/KNOWN_LIMITATIONS.md), but it does verify the *data* (the rule
table itself) actually classifies every spec §41 scenario the way the
architecture assumes, so a bad regex edit gets caught even without a
build."""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RULES_FILE = ROOT / "files" / "system" / "usr" / "lib" / "kidsos" / "models" / "text-safety" / "rules-0.1.json"
FIXTURES_DIR = ROOT / "tests" / "fixtures" / "safety" / "text"

ok = True


def fail(msg: str) -> None:
    global ok
    print(f"FAIL: {msg}")
    ok = False


def classify(text: str, rules: list) -> str:
    best_weight = 0.0
    best_category = "UNKNOWN"
    for rule in rules:
        for pattern in rule["patterns"]:
            if re.search(pattern, text, re.IGNORECASE) and rule["weight"] > best_weight:
                best_weight = rule["weight"]
                best_category = rule["category"]
    return best_category


def main() -> None:
    if not RULES_FILE.exists():
        fail(f"{RULES_FILE} does not exist")
        sys.exit(1)

    rules = json.loads(RULES_FILE.read_text(encoding="utf-8"))["rules"]

    manifest_path = FIXTURES_DIR / "fixtures.json"
    if not manifest_path.exists():
        fail(f"{manifest_path} does not exist")
        sys.exit(1)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    for entry in manifest["fixtures"]:
        fixture_path = FIXTURES_DIR / entry["file"]
        if not fixture_path.exists():
            fail(f"fixture missing: {fixture_path}")
            continue

        text = fixture_path.read_text(encoding="utf-8")
        actual = classify(text, rules)
        expected = entry["expectedCategory"]

        if actual != expected:
            fail(f"{entry['file']}: expected {expected}, rule table produced {actual}")
        else:
            print(f"OK: {entry['file']} -> {actual}")

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
