#ifndef DEEPIN_DOCTOR_PLUGIN_INTERFACE_H
#define DEEPIN_DOCTOR_PLUGIN_INTERFACE_H

#include "ModuleInterface.h"

namespace DeepinDoctor {

class PluginInterface
{
public:
    virtual ~PluginInterface() = default;

    // Plugin unique identifier
    virtual QString id() const = 0;

    // Create module instance
    virtual ModuleInterface* createModule() = 0;
};

} // namespace DeepinDoctor

Q_DECLARE_INTERFACE(DeepinDoctor::PluginInterface, "com.deepin.Doctor.PluginInterface/1.0")

#endif // DEEPIN_DOCTOR_PLUGIN_INTERFACE_H
