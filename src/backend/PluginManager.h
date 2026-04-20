#ifndef PLUGIN_MANAGER_H
#define PLUGIN_MANAGER_H

#include <QObject>
#include <QList>
#include "PluginInterface.h"

namespace DeepinDoctor {
class PluginInterface;
class ModuleInterface;
}

class ModuleManager;

class PluginManager : public QObject
{
    Q_OBJECT

public:
    explicit PluginManager(ModuleManager* moduleManager, QObject* parent = nullptr);
    ~PluginManager();

    // Load plugins from directory
    void loadPlugins(const QString& pluginDir);

    // Get loaded plugins
    QList<DeepinDoctor::PluginInterface*> plugins() const;

private:
    ModuleManager* m_moduleManager;
    QList<DeepinDoctor::PluginInterface*> m_plugins;
};

#endif // PLUGIN_MANAGER_H
