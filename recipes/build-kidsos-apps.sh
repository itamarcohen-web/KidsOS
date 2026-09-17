#!/usr/bin/bash
# BlueBuild `script` module: compiles the three KidsOS Qt6/QML apps
# (onboarding, launcher, settings) from source and installs branding
# assets + fonts. Runs inside the image build container — see
# recipes/recipe.yml.
#
# Build-only dependencies are installed and removed within this single
# script so they never appear in the final image layer.
set -oue pipefail

echo "kidsos: installing Qt6/build toolchain"
dnf5 install -y \
    cmake \
    gcc-c++ \
    extra-cmake-modules \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    qt6-qtsvg-devel

echo "kidsos: building KidsOS apps (onboarding, launcher, settings, files)"
cmake -S /tmp/kidsos-src -B /tmp/kidsos-build \
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
install -Dm644 /tmp/kidsos-src/branding/themes/plasma/KidsOS.colors /usr/share/color-schemes/KidsOS.colors

echo "kidsos: cleaning up build toolchain and staged source"
dnf5 remove -y \
    cmake \
    gcc-c++ \
    extra-cmake-modules \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    qt6-qtsvg-devel
rm -rf /tmp/kidsos-src /tmp/kidsos-build
