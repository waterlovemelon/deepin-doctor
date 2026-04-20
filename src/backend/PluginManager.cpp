#include "PluginManager.h"
#include "ModuleManager.h"
#include <QDir>
#include <QPluginLoader>
#include <QDebug>

PluginManager::PluginManager(ModuleManager* moduleManager, QObject* parent)
    : QObject(parent)
    , m_moduleManager(moduleManager)
{
}

PluginManager::~PluginManager()
{
    qDeleteAll(m_plugins);
}

void PluginManager::loadPlugins(const QString& pluginDir)
{
    QDir dir(pluginDir);

    if (!dir.exists()) {
        qWarning() << "Plugin directory does not exist:" << pluginDir;
        return;
    }

    QStringList filters;
    #ifdef Q_OS_LINUX
    filters << "*.so";
    #elif defined(Q_OS_WIN)
    filters << "*.dll";
    #elif defined(Q_OS_MAC)
    filters << "*.dylib";
    #endif

    for (const QString& file : dir.entryList(filters, QDir::Files)) {
        QString filePath = dir.absoluteFilePath(file);

        QPluginLoader loader(filePath);
        QObject* instance = loader.instance();

        if (!instance) {
            qWarning() << "Failed to load plugin:" << filePath << loader.errorString();
            continue;
        }

        auto* plugin = qobject_cast<DeepinDoctor::PluginInterface*>(instance);
        if (!plugin) {
            qWarning() << "Plugin does not implement interface:" << filePath;
            loader.unload();
            continue;
        }

        qInfo() << "Plugin loaded:" << plugin->id();
        m_plugins.append(plugin);

        // Create module and register
        DeepinDoctor::ModuleInterface* module = plugin->createModule();
        if (module) {
            m_moduleManager->registerModule(module);
        }
    }
}

QList<DeepinDoctor::PluginInterface*> PluginManager::plugins() const
{
    return m_plugins;
}
