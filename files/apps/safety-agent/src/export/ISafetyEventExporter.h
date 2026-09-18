#pragma once

#include "../../../../core/services/common/safety/SafetyTypes.h"

#include <QVariantMap>

// spec §24/§47: the schema shape a future KidsOS Parent website will
// eventually receive. NoOpSafetyEventExporter (the only implementation
// this milestone ships) writes to nothing — see IParentSyncService for
// why nothing ever leaves the device yet.
class ISafetyEventExporter
{
public:
    virtual ~ISafetyEventExporter() = default;

    // Returns SafetyAi::toExportSchema(event); a real exporter would
    // additionally hand this to IParentSyncService.
    virtual QVariantMap exportEvent(const SafetyAi::SafetyEvent &event) = 0;
};

class NoOpSafetyEventExporter : public ISafetyEventExporter
{
public:
    QVariantMap exportEvent(const SafetyAi::SafetyEvent &event) override
    {
        return SafetyAi::toExportSchema(event);
    }
};
