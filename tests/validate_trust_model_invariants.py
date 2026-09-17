#!/usr/bin/env python3
"""Source-level invariant checks for the trust model (spec §25: "if the
file changes after approval, reject installation"). This can't run the
actual logic (no Linux/Qt toolchain here — see
docs/KNOWN_LIMITATIONS.md), but it does assert the safety-critical shape
of core/services/kidsos-installer/InstallerService.cpp::approveExternal
is present, so an accidental future edit that silently drops the
re-hash-and-compare step gets caught even by someone who never notices
docs/TRUST_MODEL.md's guarantee by inspection alone.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "core/services/kidsos-installer/InstallerService.cpp"

ok = True


def fail(msg: str) -> None:
    global ok
    print(f"FAIL: {msg}")
    ok = False


def main() -> None:
    global ok
    if not SOURCE.exists():
        fail(f"{SOURCE} does not exist")
        sys.exit(1)

    text = SOURCE.read_text(encoding="utf-8")

    # Extract just the approveExternal function body (between its opening
    # and the next top-level "bool InstallerService::" or EOF).
    m = re.search(r"bool InstallerService::approveExternal.*?\n\{(.*?)\n\}\n", text, re.DOTALL)
    if not m:
        fail("could not locate approveExternal() function body")
        sys.exit(1)
    body = m.group(1)

    checks = [
        ("re-hashes the file at approval time (calls hashFile again, not just trusting the stored hash)",
         "hashFile(path)" in body or "hashFile(" in body),
        ("compares the fresh hash against the hash captured at submission",
         "currentHash" in body and "approvedHash" in body and "!=" in body),
        ("returns false / bails out on a hash mismatch before calling TrustFile",
         (lambda: (
             (idx := body.find("currentHash != approvedHash")) != -1
             and "return false" in body[idx:idx + 300]
         ))()),
        ("only calls FileGuard's TrustFile after the hash check, not before",
         body.index("TrustFile") > body.index("currentHash != approvedHash")
         if "TrustFile" in body and "currentHash != approvedHash" in body else False),
    ]

    for description, passed in checks:
        if passed:
            print(f"OK: {description}")
        else:
            fail(description)

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
