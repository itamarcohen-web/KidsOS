#!/usr/bin/bash
# BlueBuild `script` module: compiles the KidsOS Qt6/QML apps and the
# four kidsos-* D-Bus services, installs branding assets/fonts/SDDM
# theme, and provisions the system users and directories the family
# account/permission system needs (see docs/SECURITY_ARCHITECTURE.md).
#
# Build-only dependencies are installed and removed within this single
# script so they never appear in the final image layer.
set -oue pipefail

echo "kidsos: installing Qt6/build toolchain"
dnf5 install -y \
    cmake \
    gcc-c++ \
    extra-cmake-modules \
    pkgconf-pkg-config \
    systemd-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    qt6-qtsvg-devel

echo "kidsos: building KidsOS apps and services"
# CONFIG_DIRECTORY is set by BlueBuild's script module to the mounted
# files/ directory (files/CMakeLists.txt, files/apps, files/core,
# files/branding all live right there) — see recipes/recipe.yml's
# top-of-file note and docs/BUILD.md for why everything had to move
# under files/. /tmp/files is the fallback for a manual local run.
KIDSOS_SRC="${CONFIG_DIRECTORY:-/tmp/files}"
cmake -S "${KIDSOS_SRC}" -B /tmp/kidsos-build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/kidsos-build --parallel "$(nproc)"
cmake --install /tmp/kidsos-build

echo "kidsos: registering app icons in the hicolor icon theme"
install -d /usr/share/icons/hicolor/scalable/apps
install -Dm644 -t /usr/share/icons/hicolor/scalable/apps /usr/share/kidsos/icons/*.svg
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true

echo "kidsos: installing KIDS brand fonts (Rubik, Nunito — SIL OFL)"
install -d /usr/share/fonts/kidsos
curl --fail --location --silent --show-error \
    -o /usr/share/fonts/kidsos/Rubik-Variable.ttf \
    "https://github.com/googlefonts/rubik/raw/main/fonts/variable/Rubik%5Bwght%5D.ttf"
curl --fail --location --silent --show-error \
    -o /usr/share/fonts/kidsos/Nunito-Variable.ttf \
    "https://github.com/googlefonts/nunito/raw/main/fonts/variable/Nunito%5Bwght%5D.ttf"
fc-cache -f /usr/share/fonts/kidsos

echo "kidsos: installing Plasma color scheme"
install -Dm644 "${KIDSOS_SRC}/branding/themes/plasma/KidsOS.colors" /usr/share/color-schemes/KidsOS.colors

echo "kidsos: installing the KidsOS SDDM login theme"
install -d /usr/share/sddm/themes/kidsos
cp -r "${KIDSOS_SRC}/branding/sddm-theme/kidsos/." /usr/share/sddm/themes/kidsos/

echo "kidsos: provisioning system users (see docs/SECURITY_ARCHITECTURE.md)"
# kidsos-setup: runs the one-time first-boot account-creation wizard.
# No password (locked, autologin-only), no shell login otherwise needed
# beyond starting its X session.
getent passwd kidsos-setup >/dev/null || \
    useradd --system --create-home --home-dir /var/lib/kidsos-setup \
        --shell /bin/bash --comment "KidsOS first-boot setup" kidsos-setup
passwd --lock kidsos-setup

# kidsos-service: unprivileged account kidsos-policy runs as.
getent passwd kidsos-service >/dev/null || \
    useradd --system --no-create-home --shell /usr/sbin/nologin \
        --comment "KidsOS policy service" kidsos-service
passwd --lock kidsos-service

echo "kidsos: preparing /etc/kidsos policy store"
install -d -m 0750 -o root -g kidsos-service /etc/kidsos
if [[ ! -f /etc/kidsos/policy.json ]]; then
    printf '{"appPolicies":{},"managedSettings":[]}' > /etc/kidsos/policy.json
    chown root:kidsos-service /etc/kidsos/policy.json
    chmod 0640 /etc/kidsos/policy.json
fi

echo "kidsos: preparing /var/lib/kidsos state directories"
install -d -m 0755 /var/lib/kidsos/profiles      # world-readable public profile summaries
install -d -m 0700 /var/lib/kidsos/installer      # kidsos-installer's SQLite store (root-only)

echo "kidsos: enabling PAM lockout after repeated failed logins"
# authselect (not hand-edited PAM files) — see
# docs/SECURITY_ARCHITECTURE.md for why.
authselect enable-feature with-faillock || \
    echo "kidsos: WARNING — authselect with-faillock failed; verify the base image's authselect profile" >&2

echo "kidsos: compiling initial fapolicyd rules"
install -d /etc/fapolicyd/trust.d
fagenrules --load || \
    echo "kidsos: WARNING — fagenrules failed; verify fapolicyd is installed correctly" >&2

echo "kidsos: cleaning up build toolchain"
dnf5 remove -y \
    cmake \
    gcc-c++ \
    extra-cmake-modules \
    systemd-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    qt6-qtsvg-devel
# Not removing $KIDSOS_SRC (/tmp/files): it's a read-only bind mount for
# this RUN step only (BlueBuild's script module), not part of the image
# layer regardless — only our own writable scratch dir needs cleanup.
rm -rf /tmp/kidsos-build
