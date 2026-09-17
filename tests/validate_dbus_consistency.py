#!/usr/bin/env python3
"""Cross-checks the D-Bus/polkit wiring statically (regex-based — not a
substitute for actually running the services, see
docs/KNOWN_LIMITATIONS.md), catching the class of bug where a client
calls an interface/method a service doesn't actually export, or a
polkit action is referenced but never defined:

1. Every `org.kidsos.<Name>1` interface a client dials (QDBusInterface)
   is actually declared via Q_CLASSINFO("D-Bus Interface", ...) in some
   service.
2. Every systemd unit's BusName= matches a registerService() call in
   that service's own main.cpp.
3. Every polkit action ID passed to PolkitCheck::isAuthorized() is
   defined in some core/configuration/polkit/actions/*.policy file.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

ok = True


def fail(msg: str) -> None:
    global ok
    print(f"FAIL: {msg}")
    ok = False


def read_all(pattern: str) -> str:
    text = ""
    for path in ROOT.rglob(pattern):
        if ".git" in path.parts:
            continue
        text += f"\n### {path}\n" + path.read_text(encoding="utf-8", errors="ignore")
    return text


cpp_text = read_all("*.cpp") + read_all("*.h")
service_files = list(ROOT.rglob("*.cpp"))

# ---- 1. Interfaces dialed vs. declared ----
dialed = set(re.findall(r'QStringLiteral\("(org\.kidsos\.\w+1)"\)', cpp_text))
declared = set(re.findall(r'Q_CLASSINFO\("D-Bus Interface",\s*"(org\.kidsos\.\w+1)"\)', cpp_text))

undeclared = dialed - declared
if undeclared:
    fail(f"interfaces dialed by a client but never declared via Q_CLASSINFO: {sorted(undeclared)}")
else:
    print(f"OK: all {len(dialed)} dialed org.kidsos interfaces are declared by some service")

# ---- 2. systemd BusName= vs. registerService() ----
for unit in ROOT.rglob("kidsos-*.service"):
    if "core/services" in str(unit):
        continue  # source dirs, not the systemd unit files
    text = unit.read_text(encoding="utf-8")
    m = re.search(r"^BusName=(\S+)", text, re.MULTILINE)
    if not m:
        continue
    bus_name = m.group(1)
    service_name = unit.stem  # e.g. "kidsos-auth"
    main_cpp = ROOT / "core" / "services" / service_name / "main.cpp"
    if not main_cpp.exists():
        fail(f"{unit.name} has BusName={bus_name} but core/services/{service_name}/main.cpp doesn't exist")
        continue
    main_text = main_cpp.read_text(encoding="utf-8")
    if f'registerService(QStringLiteral("{bus_name}"))' not in main_text:
        fail(f"{unit.name}: BusName={bus_name} has no matching registerService() call in {main_cpp}")
    else:
        print(f"OK: {unit.name} BusName={bus_name} matches {main_cpp.relative_to(ROOT)}")

# ---- 3. polkit action IDs referenced vs. defined ----
referenced_actions = set(re.findall(r'PolkitCheck::isAuthorized\([^,]+,\s*QStringLiteral\("([\w.-]+)"\)', cpp_text))

defined_actions = set()
for policy_file in ROOT.rglob("core/configuration/polkit/actions/*.policy"):
    text = policy_file.read_text(encoding="utf-8")
    defined_actions |= set(re.findall(r'<action id="([\w.-]+)">', text))

missing_actions = referenced_actions - defined_actions
if missing_actions:
    fail(f"polkit actions referenced in code but not defined in any .policy file: {sorted(missing_actions)}")
else:
    print(f"OK: all {len(referenced_actions)} referenced polkit actions are defined")

if not ok:
    sys.exit(1)
