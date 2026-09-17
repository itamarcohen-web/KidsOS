# Building, testing and booting KidsOS

This repository was authored on macOS without `podman`/`docker`, a Qt6
toolchain, or KVM — so none of the steps below were actually executed
during development; they're the exact commands to run on a Linux host or
in CI. See `docs/KNOWN_LIMITATIONS.md` for the full list of what could
only be validated by static review (YAML/JSON syntax, manual QML read).

## 1. Validate the recipe locally (fast, no build)

```bash
python3 tests/validate_recipe.py
python3 tests/validate_locales.py
```

Both were run during development and pass — they check YAML/JSON syntax
and that `en`/`he`/`ar` locale files have identical key sets.

## 2. Build the app binaries directly (sanity check, no image)

On a Linux machine with Qt6 + KDE Frameworks 6 dev packages
(`qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel
qt6-qtsvg-devel cmake gcc-c++ extra-cmake-modules` on Fedora):

```bash
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel
```

To run an app straight from the source tree without installing it
system-wide:

```bash
export QML2_IMPORT_PATH="$PWD/branding/themes/qml:$PWD/core/localization:$PWD/apps/common/qml"
export KIDSOS_DEV_APP_QML_DIR="$PWD/apps/onboarding/qml"
export KIDSOS_DEV_LOCALES_PATH="file://$PWD/core/localization/strings/"
./build/apps/onboarding/kidsos-onboarding
```

`KIDSOS_DEV_LOCALES_PATH` is read by `main.cpp` and passed to
`LocalizationManager.qml` as a context property override, so you don't
need to install anything system-wide to run an app straight from the
source tree.

Swap `apps/onboarding` for `apps/launcher` or `apps/settings` to run the
other two.

## 3. Build the full BlueBuild OCI image

Requires a Linux host (or macOS/Windows with a Linux VM) with `podman` or
`docker`, and the [BlueBuild CLI](https://blue-build.org):

```bash
# Install the CLI (see blue-build.org for current instructions)
curl -LO https://github.com/blue-build/cli/releases/latest/download/bluebuild-installer.sh
sh bluebuild-installer.sh

# From the repository root:
bluebuild build recipes/recipe.yml
```

This runs the `recipes/build-kidsos-apps.sh` script module inside the
container (compiling the three Qt6 apps, fetching the Rubik/Baloo 2
fonts — this step needs network access), layers on the `rpm-ostree` and
`default-flatpaks` modules, and produces a local OCI image.

In CI, `.github/workflows/build.yml` calls BlueBuild's reusable GitHub
Actions workflow on every push to `main`. **Verify that workflow file
against the current official template
(<https://github.com/blue-build/template>) before relying on it** — it
could not be run in this development environment, and BlueBuild's
reusable-workflow interface does change between releases. You'll also
need a cosign keypair for the `signing` module:

```bash
cosign generate-key-pair
# add cosign.key contents as the SIGNING_SECRET repo secret
# commit cosign.pub to the repo root (referenced by the signing module)
```

## 4. Generate a bootable ISO

BlueBuild images are meant to be installed via `rpm-ostree rebase` onto
an existing Fedora system, but for a from-scratch VM test you want an
installer ISO. Use
[bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
against the built/pushed image:

```bash
sudo podman run --rm -it --privileged \
  --pull=newer \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso \
  ghcr.io/<your-org>/kidsos:latest
```

The resulting `.iso` lands in `./output/bootiso/`.

## 5. Boot the ISO in a VM and test

```bash
qemu-img create -f qcow2 kidsos-test.qcow2 40G
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 4 \
  -cdrom ./output/bootiso/install.iso \
  -hda kidsos-test.qcow2 \
  -boot d
```

(GNOME Boxes, virt-manager, or UTM on Apple Silicon Macs work too — UTM
uses its own QEMU/Apple Virtualization backend and is the most practical
option if your build host is a Mac.)

Install to the virtual disk, reboot, and walk through the manual QA
checklist at `tests/checklist_manual_qa.md`: onboarding in English,
Hebrew and Arabic; RTL mirroring; keyboard-only completion; confirming
`id kid` shows no `wheel` membership; confirming the desktop appears
after "Enter KIDS".
