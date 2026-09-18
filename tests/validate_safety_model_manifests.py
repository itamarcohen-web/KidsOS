#!/usr/bin/env python3
"""Validates every /usr/lib/kidsos/models/**/model.json manifest (spec
§9/§36, vision-clarification §6): required fields present, valid JSON,
approvalStatus is one of the defined ModelApprovalStatus values, and —
for any manifest whose "file" actually exists on disk (i.e. a real
model was shipped, not just a placeholder) — its sha256 field matches
the file's real hash, so ModelManager::verifyIntegrity() won't silently
reject a model someone forgot to re-hash after editing."""
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODELS_DIR = ROOT / "files" / "system" / "usr" / "lib" / "kidsos" / "models"

REQUIRED_FIELDS = {
    "name", "version", "file", "sha256", "license", "source",
    "supportedCategories", "modelSizeBytes", "runtime", "minimumHardware",
    "provenanceNotes", "approvalStatus",
}
VALID_APPROVAL_STATUSES = {
    "UNREVIEWED", "DEVELOPMENT_ONLY", "LEGAL_REVIEW_REQUIRED",
    "APPROVED_FOR_DISTRIBUTION", "DISABLED",
}

ok = True


def fail(msg: str) -> None:
    global ok
    print(f"FAIL: {msg}")
    ok = False


def main() -> None:
    manifests = sorted(MODELS_DIR.rglob("model.json"))
    if not manifests:
        fail(f"no model.json manifests found under {MODELS_DIR}")
        sys.exit(1)

    for manifest_path in manifests:
        rel = manifest_path.relative_to(ROOT)
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            fail(f"{rel} is not valid JSON: {e}")
            continue

        missing = REQUIRED_FIELDS - manifest.keys()
        if missing:
            fail(f"{rel} is missing required fields: {sorted(missing)}")
            continue

        if manifest["approvalStatus"] not in VALID_APPROVAL_STATUSES:
            fail(f"{rel} has invalid approvalStatus {manifest['approvalStatus']!r}")
            continue

        data_file = manifest_path.parent / manifest["file"]
        if data_file.exists():
            digest = hashlib.sha256(data_file.read_bytes()).hexdigest()
            if digest != manifest["sha256"]:
                fail(f"{rel}: sha256 does not match {data_file.name} "
                     f"(manifest says {manifest['sha256']}, actual is {digest})")
                continue
            print(f"OK: {rel} — {manifest['file']} present and hash matches")
        else:
            # Expected for the vision-safety placeholders this milestone
            # ships (no model bundled) — approvalStatus must not claim
            # otherwise.
            if manifest["approvalStatus"] == "APPROVED_FOR_DISTRIBUTION":
                fail(f"{rel}: approvalStatus is APPROVED_FOR_DISTRIBUTION but "
                     f"{manifest['file']} does not exist — nothing should be "
                     "approved without an actual model file present")
                continue
            print(f"OK: {rel} — no model file yet ({manifest['approvalStatus']}, as expected)")

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
