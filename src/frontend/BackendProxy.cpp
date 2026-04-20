#include "BackendProxy.h"
#include <QDBusConnection>
#include <QDBusReply>
#include <QDebug>
#include <QDir>

BackendProxy::BackendProxy(QObject* parent)
    : QObject(parent)
{
    m_interface = new QDBusInterface(m_serviceName, m_objectPath, m_interfaceName,
                                     QDBusConnection::sessionBus(), this);

    if (!m_interface->isValid()) {
        qWarning() << "DBus interface not valid:" << m_interface->lastError().message();
    }

    // Connect signals
    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "CollectProgress",
        this, SLOT(collectProgress(QString, QString, double))
    );

    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "CollectFinished",
        this, SLOT(collectFinished(QString, QString))
    );

    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "ExportProgress",
        this, SIGNAL(exportProgress(double))
    );

    QDBusConnection::sessionBus().connect(
        m_serviceName, m_objectPath, m_interfaceName,
        "ExportFinished",
        this, SIGNAL(exportFinished(bool, QString))
    );
}

BackendProxy::~BackendProxy()
{
}

QStringList BackendProxy::listModules()
{
    QDBusReply<QStringList> reply = m_interface->call("ListModules");
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "ListModules failed:" << reply.error().message();
    return {};
}

QString BackendProxy::collect(const QStringList& modules)
{
    QDBusReply<QString> reply = m_interface->call("Collect", modules);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "Collect failed:" << reply.error().message();
    return {};
}

QString BackendProxy::detect(const QStringList& modules)
{
    QDBusReply<QString> reply = m_interface->call("Detect", modules);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "Detect failed:" << reply.error().message();
    return {};
}

bool BackendProxy::exportResult(const QString& result, const QString& outputPath)
{
    QDBusReply<bool> reply = m_interface->call("Export", result, outputPath);
    if (reply.isValid()) {
        return reply.value();
    }
    qWarning() << "Export failed:" << reply.error().message();
    return false;
}

QString BackendProxy::homePath() const
{
    return QDir::homePath();
}
