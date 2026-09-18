#pragma once

#include <QString>

// spec §9/§22/§36: models are packaged locally under
// /usr/lib/kidsos/models/<name>/ alongside a model.json manifest
// (version, sha256, license, supported categories, approval status —
// see docs/SAFETY_AI.md for the exact schema). ModelManager verifies
// integrity before anything is allowed to load a model's data file;
// nothing is ever fetched from a URL at runtime.
struct ModelManifest {
    QString name;
    QString version;
    QString dataFile;      // relative to the manifest's own directory
    QString sha256;
    QString license;
    QString approvalStatus; // ModelApprovalStatus as a string (spec §7 of the vision clarification)
    bool valid = false;
};

namespace ModelManager {

// Reads <modelDir>/model.json. valid=false if missing/malformed.
ModelManifest loadManifest(const QString &modelDir);

// Hashes <modelDir>/<manifest.dataFile> and compares against
// manifest.sha256. False on any mismatch or read failure — callers
// must not load the data file when this returns false (spec §22:
// "Return MODEL_INTEGRITY_FAILURE").
bool verifyIntegrity(const QString &modelDir, const ModelManifest &manifest);

}
