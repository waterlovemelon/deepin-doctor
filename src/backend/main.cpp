#include "DBusService.h"
#include "ModuleManager.h"
#include "PluginManager.h"
#include "ModuleInterface.h"
#include "modules/network/NetworkModule.h"
#include "modules/system/SystemModule.h"
#include "modules/environment/EnvironmentModule.h"
#include "modules/logs/LogsModule.h"
#include <QCoreApplication>
#include <QTimer>

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName("deepin-doctor-daemon");
    QCoreApplication::setApplicationVersion("0.1.0");

    // Create module manager
    ModuleManager moduleManager;

    // Register built-in modules
    moduleManager.registerModule(new DeepinDoctor::NetworkModule);
    moduleManager.registerModule(new DeepinDoctor::SystemModule);
    moduleManager.registerModule(new DeepinDoctor::EnvironmentModule);
    moduleManager.registerModule(new DeepinDoctor::LogsModule);

    // Load plugins
    PluginManager pluginManager(&moduleManager);
    QString pluginDir = QCoreApplication::applicationDirPath() + "/../lib/deepin-doctor/plugins";
    pluginManager.loadPlugins(pluginDir);

    // Create DBus service
    DBusService dbusService(&moduleManager);

    if (!dbusService.registerService()) {
        qCritical() << "Failed to register DBus service";
        return 1;
    }

    qInfo() << "deepin-doctor-daemon started";

    return app.exec();
}
