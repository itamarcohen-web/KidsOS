#pragma once

#include <QDBusMessage>
#include <QString>

// Checks a D-Bus caller's authorization for a polkit action via a direct
// D-Bus call to org.freedesktop.PolicyKit1.Authority — no polkit-qt
// dependency needed, just the same mechanism every polkit-aware service
// (PackageKit, systemd, NetworkManager, ...) already uses.
//
// `interactive`: if true, polkit may show its own authentication dialog
// (the standard KDE polkit-kde-agent prompt) and block until the user
// answers it or cancels. Every KidsOS approval action uses interactive
// checks with auth_admin (see actions/*.policy) so a Parent password
// prompt appears at the moment of approval, every time — never cached.
namespace PolkitCheck {

bool isAuthorized(const QDBusMessage &callerMessage, const QString &actionId,
                   bool interactive = true);

}
