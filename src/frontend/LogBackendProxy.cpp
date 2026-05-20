#include "LogBackendProxy.h"
#include <QDBusConnection>
#include <QDBusReply>
#include <QDebug>

LogBackendProxy::LogBackendProxy(QObject* parent)
    : QObject(parent)
{
    m_interface = new QDBusInterface(m_serviceName, m_objectPath, m_interfaceName,
                                     QDBusConnection::sessionBus(), this);

    if (!m_interface->isValid()) {
        qWarning() << "LogService DBus interface not valid:" << m_interface->lastError().message();
    }

    // Connect signals
    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "DebugModeChanged",
        this, SIGNAL(debugModeChanged(QString, bool))
    );

    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "ExportProgress",
        this, SIGNAL(exportProgress(QString, double))
    );

    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "ExportFinished",
        this, SIGNAL(exportFinished(bool, QString))
    );
}

LogBackendProxy::~LogBackendProxy()
{
}

bool LogBackendProxy::checkCommand()
{
    QDBusReply<bool> reply = m_interface->call("CheckCommand");
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "CheckCommand failed:" << reply.error().message();
    return false;
}

QStringList LogBackendProxy::listComponents()
{
    QDBusReply<QStringList> reply = m_interface->call("ListComponents");
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "ListComponents failed:" << reply.error().message();
    return {};
}

bool LogBackendProxy::setDebugMode(const QStringList& components, bool enabled)
{
    QDBusReply<bool> reply = m_interface->call("SetDebugMode",
                                               QVariant::fromValue(components), enabled);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "SetDebugMode failed:" << reply.error().message();
    return false;
}

bool LogBackendProxy::isDebugEnabled(const QString& component)
{
    QDBusReply<bool> reply = m_interface->call("IsDebugEnabled", component);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "IsDebugEnabled failed:" << reply.error().message();
    return false;
}

bool LogBackendProxy::exportLogs(const QStringList& components, const QString& type, const QString& path)
{
    QDBusReply<bool> reply = m_interface->call("ExportLogs",
                                               QVariant::fromValue(components), type, path);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "ExportLogs failed:" << reply.error().message();
    return false;
}
