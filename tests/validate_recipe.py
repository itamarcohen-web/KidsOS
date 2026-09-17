#!/usr/bin/env python3
"""Validates recipes/recipe.yml: valid YAML, expected top-level keys,
and that every 'files' module source path actually exists in the repo
(catches typos before a real container build wastes time on them)."""
import pathlib
import sys

try:
    import yaml
except ImportError:
    sys.exit("pyyaml is required: pip install pyyaml")

ROOT = pathlib.Path(__file__).resolve().parent.parent
RECIPE = ROOT / "recipes" / "recipe.yml"

REQUIRED_KEYS = {"name", "description", "base-image", "image-version", "modules"}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def main() -> None:
    if not RECIPE.exists():
        fail(f"{RECIPE} does not exist")

    with RECIPE.open() as f:
        recipe = yaml.safe_load(f)

    missing = REQUIRED_KEYS - recipe.keys()
    if missing:
        fail(f"recipe.yml is missing required keys: {sorted(missing)}")

    if not isinstance(recipe["modules"], list) or not recipe["modules"]:
        fail("recipe.yml 'modules' must be a non-empty list")

    # BlueBuild requires every 'files'/'script' module reference to live
    # under a literal top-level files/ directory (mounted into the build
    # container as $CONFIG_DIRECTORY) — see the note at the top of
    # recipes/recipe.yml and docs/BUILD.md.
    files_dir = ROOT / "files"
    checked = 0
    for module in recipe["modules"]:
        if module.get("type") != "files":
            continue
        for entry in module.get("files", []):
            source = files_dir / entry["source"]
            if not source.exists():
                fail(f"files module source does not exist under files/: {entry['source']}")
            checked += 1

    scripts_dir = files_dir / "scripts"
    for module in recipe["modules"]:
        if module.get("type") != "script":
            continue
        for script in module.get("scripts", []):
            script_path = scripts_dir / script
            if not script_path.exists():
                fail(f"script module references missing script: {script}")
            checked += 1

    print(f"OK: recipe.yml is valid, {len(recipe['modules'])} modules, "
          f"{checked} file/script references resolved")


if __name__ == "__main__":
    main()
