#pragma once

#include <QString>

// Content-signature file classification (spec §21-23) — never trusts a
// file extension alone. See docs/TRUST_MODEL.md.
namespace FileClassifier {

// One of: "appimage", "elf", "script", "deb", "rpm", "document" (not
// subject to the approval flow), "unknown" (treated conservatively —
// routed through the approval flow like an executable, since an
// unrecognized binary-ish file is exactly the "unknown → block" case
// spec §20 describes).
QString classify(const QString &filePath);

// True for classify() results that must go through
// SubmitExternalInstallRequest before they may run (everything except
// "document").
bool requiresApproval(const QString &kind);

}
