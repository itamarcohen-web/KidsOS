#pragma once

#include <QString>
#include <QVariantMap>

// Structured, append-only audit trail for security-sensitive actions
// (spec §35). Writes to the systemd journal (sd_journal_send) rather
// than a hand-rolled log file — the journal is the standard Linux
// mechanism for this, gives free rotation/persistence/tamper-evidence
// options (journald's Seal= / Forward Secure Sealing), and every entry
// is queryable with:
//
//   journalctl KIDSOS_AUDIT=1
//   journalctl KIDSOS_AUDIT=1 KIDSOS_ACTION=parent.login
//
// Never pass a password or PIN value into `fields` — see the call sites
// in each service for what is/isn't logged.
namespace AuditLog {

// action examples: "parent.login", "child.login", "install.request",
// "install.approve", "install.deny", "external.request",
// "external.approve", "external.deny", "trust.revoke".
void record(const QString &action, const QVariantMap &fields = {});

}
