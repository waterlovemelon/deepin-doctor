#include "LogDBusAdaptor.h"
#include "LogDBusService.h"

LogDBusAdaptor::LogDBusAdaptor(LogDBusService* parent)
    : QDBusAbstractAdaptor(parent)
{
    setAutoRelaySignals(true);
}

bool LogDBusAdaptor::CheckCommand()
{
    return static_cast<LogDBusService*>(parent())->CheckCommand();
}

QStringList LogDBusAdaptor::ListComponents()
{
    return static_cast<LogDBusService*>(parent())->ListComponents();
}

bool LogDBusAdaptor::SetDebugMode(const QStringList& components, bool enabled)
{
    return static_cast<LogDBusService*>(parent())->SetDebugMode(components, enabled);
}

bool LogDBusAdaptor::IsDebugEnabled(const QString& component)
{
    return static_cast<LogDBusService*>(parent())->IsDebugEnabled(component);
}

bool LogDBusAdaptor::ExportLogs(const QStringList& components, const QString& type, const QString& path)
{
    return static_cast<LogDBusService*>(parent())->ExportLogs(components, type, path);
}
