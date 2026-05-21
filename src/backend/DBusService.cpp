#include "DBusService.h"
#include "DBusAdaptor.h"
#include "ModuleManager.h"
#include "ModuleInterface.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QJsonDocument>
#include <QJsonArray>
#include <QFile>
#include <QDir>
#include <QTemporaryDir>
#include <QProcess>
#include <QDebug>

DBusService::DBusService(ModuleManager* moduleManager, QObject* parent)
    : QObject(parent)
    , m_moduleManager(moduleManager)
{
    new DBusAdaptor(this);

    // Connect ModuleManager signals
    connect(m_moduleManager, &ModuleManager::collectProgress,
            this, &DBusService::CollectProgress);
    connect(m_moduleManager, &ModuleManager::collectFinished,
            this, &DBusService::CollectFinished);
}

DBusService::~DBusService()
{
    QDBusConnection::sessionBus().unregisterObject(m_objectPath);
    QDBusConnection::sessionBus().unregisterService(m_serviceName);
}

bool DBusService::registerService()
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

QStringList DBusService::ListModules()
{
    return m_moduleManager->listModules();
}

QString DBusService::Collect(const QStringList& modules)
{
    QString taskId = m_moduleManager->collect(modules);
    return taskId;
}

QString DBusService::Detect(const QStringList& modules)
{
    QList<DeepinDoctor::Issue> issues = m_moduleManager->detect(modules);

    QJsonArray issuesArray;
    for (const auto& issue : issues) {
        issuesArray.append(issue.toJson());
    }

    return QJsonDocument(issuesArray).toJson();
}

bool DBusService::Export(const QString& result, const QString& outputPath)
{
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(result.toUtf8(), &error);

    if (error.error != QJsonParseError::NoError) {
        qWarning() << "Failed to parse JSON:" << error.errorString();
        return false;
    }

    QJsonObject root = doc.object();

    // Create temporary directory for export
    QTemporaryDir tempDir;
    if (!tempDir.isValid()) {
        qWarning() << "Failed to create temporary directory";
        return false;
    }

    QString exportDir = tempDir.path();

    // Write manifest and module results
    for (auto it = root.begin(); it != root.end(); ++it) {
        QString key = it.key();
        QJsonValue value = it.value();

        if (key == "manifest") {
            // Write manifest.json
            QString manifestPath = exportDir + "/manifest.json";
            QFile manifestFile(manifestPath);
            if (manifestFile.open(QIODevice::WriteOnly)) {
                manifestFile.write(QJsonDocument(value.toObject()).toJson());
                manifestFile.close();
            }
        } else {
            // Write module data
            QString moduleDir = exportDir + "/" + key;
            QDir().mkpath(moduleDir);

            QString moduleFile = moduleDir + "/" + key + ".json";
            QFile file(moduleFile);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(QJsonDocument(value.toObject()).toJson());
                file.close();
            }

            // Extract logs if present
            QJsonObject moduleObj = value.toObject();
            if (moduleObj.contains("logs")) {
                QJsonObject logsObj = moduleObj["logs"].toObject();
                QString logsDir = moduleDir + "/logs";
                QDir().mkpath(logsDir);

                for (auto logIt = logsObj.begin(); logIt != logsObj.end(); ++logIt) {
                    QString logFile = logsDir + "/" + logIt.key() + ".txt";
                    QFile lf(logFile);
                    if (lf.open(QIODevice::WriteOnly | QIODevice::Text)) {
                        lf.write(logIt.value().toString().toUtf8());
                        lf.close();
                    }
                }
            }
        }
    }

    // Create tar.gz archive
    QProcess tar;
    tar.start("tar", QStringList() << "-czf" << outputPath << "-C" << exportDir << ".");
    tar.waitForFinished(30000);

    if (tar.exitCode() != 0) {
        qWarning() << "Failed to create archive:" << tar.readAllStandardError();
        return false;
    }

    qInfo() << "Exported to" << outputPath;
    return true;
}
