#pragma once

#include <QVariantMap>

// spec §25/§47/§48: placeholder architecture for a future
// device-identity-based Parent-account sync. NoOpParentSyncService is
// the only implementation this milestone ships and it never makes a
// network request — that's what makes "internet disconnected, safety
// AI still works" true by construction rather than by policy (spec
// §22/§51).
class IParentSyncService
{
public:
    virtual ~IParentSyncService() = default;

    virtual bool isEnabled() const = 0;
    virtual bool sync(const QVariantMap &exportedEvent) = 0; // never actually called while disabled
};

class NoOpParentSyncService : public IParentSyncService
{
public:
    bool isEnabled() const override { return false; }
    bool sync(const QVariantMap &) override { return false; }
};
