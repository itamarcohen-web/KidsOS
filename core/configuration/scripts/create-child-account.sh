#!/usr/bin/bash
# Creates the default KidsOS child account on first boot: a standard,
# non-administrator Linux user. It is NOT added to `wheel` (or any other
# sudoers-equivalent group), so it has no admin rights on the system —
# see core/configuration/polkit/10-kidsos-child-restrictions.rules for the
# belt-and-suspenders policy layer on top of that.
#
# Installed to /usr/libexec/kidsos/create-child-account.sh by the BlueBuild
# recipe (recipes/recipe.yml) and run once by kidsos-firstboot.service.
set -euo pipefail

CHILD_USER="kid"
CHILD_GROUP="kidsos-children"

if id "${CHILD_USER}" &>/dev/null; then
    echo "kidsos: ${CHILD_USER} already exists, skipping account creation"
    exit 0
fi

getent group "${CHILD_GROUP}" >/dev/null || groupadd --system "${CHILD_GROUP}"

useradd \
    --create-home \
    --shell /bin/bash \
    --comment "KidsOS child account" \
    --gid "${CHILD_GROUP}" \
    "${CHILD_USER}"

# No password is set here: the device boots straight to KidsOS's own
# onboarding UI (autologin is configured by the display manager for this
# account), and authentication going forward is the in-app child PIN
# created during onboarding (apps/onboarding — ProfileBridge::setChildPin),
# not a Linux account password. This account is intentionally locked out
# of interactive Linux login prompts.
passwd --lock "${CHILD_USER}"

echo "kidsos: created non-admin child account '${CHILD_USER}'"
