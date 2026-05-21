#include "LogDBusService.h"
#include "LogDBusAdaptor.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QProcess>
#include <QDebug>

LogDBusService::LogDBusService(QObject* parent)
    : QObject(parent)
{
    new LogDBusAdaptor(this);
}

LogDBusService::~LogDBusService()
{
    QDBusConnection::sessionBus().unregisterObject(m_objectPath);
    QDBusConnection::sessionBus().unregisterService(m_serviceName);
}

bool LogDBusService::registerService()
{
    QDBusConnection bus = QDBusConnection::sessionBus();

    if (!bus.registerService(m_serviceName)) {
        qWarning() << "Failed to register DBus service:" << m_serviceName
                   << bus.lastError().message();
        return false;
    }

    if (!bus.registerObject(m_objectPath, this, QDBusConnection::ExportAdaptors)) {
        qWarning() << "Failed to register DBus object:" << m_objectPath
                   << bus.lastError().message();
        return false;
    }

    qInfo() << "DBus service registered:" << m_serviceName << m_objectPath;
    return true;
}

bool LogDBusService::CheckCommand()
{
    return QProcess::execute("which", {"deepin-debug-config"}) == 0;
}

QStringList LogDBusService::ListComponents()
{
    return {
        "dde-desktop",
        "dde-dock",
        "dde-launcher",
        "dde-control-center",
        "dde-file-manager",
        "dde-polkit-agent",
        "dde-session-daemon",
        "dde-system-daemon"
    };
}

bool LogDBusService::SetDebugMode(const QStringList& components, bool enabled)
{
    if (!CheckCommand()) {
        qWarning() << "deepin-debug-config command not found";
        return false;
    }

    QString action = enabled ? "enable" : "disable";

    for (const QString& component : components) {
        int exitCode = QProcess::execute("deepin-debug-config", {action, component});
        if (exitCode != 0) {
            qWarning() << "Failed to" << action << "debug mode for component:" << component;
            return false;
        }

        qInfo() << "Debug mode" << action << "for component:" << component;
        Q_EMIT DebugModeChanged(component, enabled);
    }

    return true;
}

bool LogDBusService::IsDebugEnabled(const QString& component)
{
    QProcess process;
    process.start("deepin-debug-config", {"status", component});
    process.waitForFinished(5000);
    return process.exitCode() == 0;
}

bool LogDBusService::ExportLogs(const QStringList& components, const QString& type, const QString& path)
{
    Q_UNUSED(components);
    Q_UNUSED(type);

    qInfo() << "Export logs stub called for path:" << path;
    Q_EMIT ExportFinished(true, path);
    return true;
}
