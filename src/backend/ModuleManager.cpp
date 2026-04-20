#include "ModuleManager.h"
#include <QUuid>
#include <QtConcurrent>
#include <QJsonDocument>
#include <QDebug>

ModuleManager::ModuleManager(QObject* parent)
    : QObject(parent)
{
}

ModuleManager::~ModuleManager()
{
    qDeleteAll(m_modules);
}

void ModuleManager::registerModule(DeepinDoctor::ModuleInterface* module)
{
    if (module && !m_modules.contains(module->name())) {
        m_modules[module->name()] = module;
        qInfo() << "Module registered:" << module->name() << module->version();
    }
}

QStringList ModuleManager::listModules() const
{
    return m_modules.keys();
}

QString ModuleManager::collect(const QStringList& modules)
{
    QString taskId = QUuid::createUuid().toString();

    QtConcurrent::run([this, modules, taskId]() {
        QJsonObject result;

        QJsonObject manifest;
        manifest["timestamp"] = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
        manifest["version"] = "0.1.0";
        manifest["modules"] = QJsonArray::fromStringList(modules);
        result["manifest"] = manifest;

        for (const QString& modName : modules) {
            if (m_modules.contains(modName)) {
                try {
                    QJsonObject modResult;
                    m_modules[modName]->collect(modResult);
                    result[modName] = modResult;

                    emit collectProgress(taskId, modName, 1.0);
                } catch (const std::exception& e) {
                    result[modName] = QJsonObject{
                        {"error", QString(e.what())}
                    };
                    qWarning() << "Module collect failed:" << modName << e.what();
                }
            } else {
                qWarning() << "Module not found:" << modName;
            }
        }

        emit collectFinished(taskId, QJsonDocument(result).toJson());
    });

    return taskId;
}

QList<DeepinDoctor::Issue> ModuleManager::detect(const QStringList& modules)
{
    QList<DeepinDoctor::Issue> allIssues;

    for (const QString& modName : modules) {
        if (m_modules.contains(modName)) {
            try {
                QList<DeepinDoctor::Issue> issues = m_modules[modName]->detect();
                allIssues.append(issues);
            } catch (const std::exception& e) {
                qWarning() << "Module detect failed:" << modName << e.what();
            }
        }
    }

    return allIssues;
}
