#!/usr/bin/env bash
# Runs every static check that doesn't require a container runtime or Qt
# toolchain. See docs/BUILD.md for the full build/boot verification
# steps that require a Linux host.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== recipe.yml =="
python3 tests/validate_recipe.py

echo
echo "== locale files =="
python3 tests/validate_locales.py

echo
echo "== brand color tokens =="
python3 tests/validate_brand_colors.py

echo
echo "== D-Bus / polkit consistency =="
python3 tests/validate_dbus_consistency.py

echo
echo "== trust model invariants =="
python3 tests/validate_trust_model_invariants.py

echo
echo "All static checks passed."
