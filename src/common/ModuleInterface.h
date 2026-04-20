#ifndef DEEPIN_DOCTOR_MODULE_INTERFACE_H
#define DEEPIN_DOCTOR_MODULE_INTERFACE_H

#include "Types.h"
#include <QString>
#include <QJsonObject>

namespace DeepinDoctor {

class ModuleInterface
{
public:
    virtual ~ModuleInterface() = default;

    // Module metadata
    virtual QString name() const = 0;
    virtual QString description() const = 0;
    virtual QString version() const = 0;

    // Collection operation
    virtual void collect(QJsonObject& result) = 0;

    // Detection operation
    virtual QList<Issue> detect() = 0;

    // Progress feedback (0.0 - 1.0)
    virtual float progress() const = 0;

    // Cancel ongoing operation
    virtual void cancel() = 0;

    // Timeout in seconds
    virtual int timeout() const { return 30; }

    // Check if module is currently running
    virtual bool isRunning() const = 0;
};

} // namespace DeepinDoctor

Q_DECLARE_INTERFACE(DeepinDoctor::ModuleInterface, "com.deepin.Doctor.ModuleInterface/1.0")

#endif // DEEPIN_DOCTOR_MODULE_INTERFACE_H
