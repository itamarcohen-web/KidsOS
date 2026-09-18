#!/usr/bin/env python3
"""MockVisionEngine.cpp (spec vision-clarification §4) hardcodes the
SHA-256 hashes of the synthetic PNG fixtures in
tests/fixtures/safety/images/ so it can return deterministic results
without ever inspecting real pixel content. This catches the failure
mode where a fixture file changes (or is regenerated) but the hardcoded
hash in the C++ source isn't updated to match — the mock would then
silently stop recognizing its own test image."""
import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURES_DIR = ROOT / "tests" / "fixtures" / "safety" / "images"
MOCK_ENGINE_CPP = ROOT / "files" / "apps" / "safety-agent" / "src" / "ai" / "MockVisionEngine.cpp"

# fixture filename -> expected category comment MockVisionEngine.cpp
# associates with its hash (the mapping is via hash value alone in the
# source; this table just lets us report *which* fixture broke).
EXPECTED_FIXTURES = [
    "synthetic_violence.png",
    "synthetic_adult_content.png",
    "synthetic_self_harm_indicator.png",
]

ok = True


def fail(msg: str) -> None:
    global ok
    print(f"FAIL: {msg}")
    ok = False


def main() -> None:
    if not MOCK_ENGINE_CPP.exists():
        fail(f"{MOCK_ENGINE_CPP} does not exist")
        sys.exit(1)

    source = MOCK_ENGINE_CPP.read_text(encoding="utf-8")
    hashes_in_source = set(re.findall(r'"([0-9a-f]{64})"', source))

    for name in EXPECTED_FIXTURES:
        path = FIXTURES_DIR / name
        if not path.exists():
            fail(f"expected fixture missing: {path}")
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest not in hashes_in_source:
            fail(f"{name}'s current hash ({digest}) is not hardcoded anywhere in {MOCK_ENGINE_CPP.relative_to(ROOT)} "
                 "— MockVisionEngine will no longer recognize this fixture")
        else:
            print(f"OK: {name} hash matches a case in MockVisionEngine.cpp")

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
