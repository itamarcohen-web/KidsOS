#!/usr/bin/env python3
"""Validates core/localization/strings/*.json: each is valid JSON, and
en/he/ar all expose exactly the same set of translation keys (so no
onboarding or desktop screen can silently fall back to a raw key string
in one language but not the others)."""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
STRINGS_DIR = ROOT / "core" / "localization" / "strings"
LANGUAGES = ["en", "he", "ar"]


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def flatten_keys(obj, prefix=""):
    keys = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            path = f"{prefix}.{k}" if prefix else k
            if isinstance(v, dict):
                keys |= flatten_keys(v, path)
            else:
                keys.add(path)
    return keys


def main() -> None:
    tables = {}
    for lang in LANGUAGES:
        path = STRINGS_DIR / f"{lang}.json"
        if not path.exists():
            fail(f"missing locale file: {path}")
        with path.open(encoding="utf-8") as f:
            try:
                tables[lang] = json.load(f)
            except json.JSONDecodeError as e:
                fail(f"{path} is not valid JSON: {e}")

    key_sets = {lang: flatten_keys(t) - {"meta.language", "meta.nativeName", "meta.direction"}
                for lang, t in tables.items()}

    baseline_lang = "en"
    baseline = key_sets[baseline_lang]

    ok = True
    for lang in LANGUAGES:
        if lang == baseline_lang:
            continue
        missing = baseline - key_sets[lang]
        extra = key_sets[lang] - baseline
        if missing:
            print(f"FAIL: {lang}.json is missing keys present in en.json: {sorted(missing)}")
            ok = False
        if extra:
            print(f"FAIL: {lang}.json has keys not present in en.json: {sorted(extra)}")
            ok = False

    if not ok:
        sys.exit(1)

    for lang in LANGUAGES:
        direction = tables[lang]["meta"]["direction"]
        expected = "rtl" if lang in ("he", "ar") else "ltr"
        if direction != expected:
            fail(f"{lang}.json meta.direction is '{direction}', expected '{expected}'")

    print(f"OK: {len(baseline)} keys, identical across {', '.join(LANGUAGES)}")


if __name__ == "__main__":
    main()
