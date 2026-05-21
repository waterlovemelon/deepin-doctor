#include "DBusAdaptor.h"
#include "DBusService.h"

DBusAdaptor::DBusAdaptor(DBusService* parent)
    : QDBusAbstractAdaptor(parent)
{
    setAutoRelaySignals(true);
}

QStringList DBusAdaptor::ListModules()
{
    return static_cast<DBusService*>(parent())->ListModules();
}

QString DBusAdaptor::Collect(const QStringList& modules)
{
    return static_cast<DBusService*>(parent())->Collect(modules);
}

QString DBusAdaptor::Detect(const QStringList& modules)
{
    return static_cast<DBusService*>(parent())->Detect(modules);
}

bool DBusAdaptor::Export(const QString& result, const QString& outputPath)
{
    return static_cast<DBusService*>(parent())->Export(result, outputPath);
}
