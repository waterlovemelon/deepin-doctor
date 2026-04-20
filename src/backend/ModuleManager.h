#ifndef MODULE_MANAGER_H
#define MODULE_MANAGER_H

#include <QObject>
#include <QMap>
#include <QJsonObject>
#include "ModuleInterface.h"

namespace DeepinDoctor {
class ModuleInterface;
}

class ModuleManager : public QObject
{
    Q_OBJECT

public:
    explicit ModuleManager(QObject* parent = nullptr);
    ~ModuleManager();

    // Register module
    void registerModule(DeepinDoctor::ModuleInterface* module);

    // List all registered modules
    QStringList listModules() const;

    // Collect information from modules
    QString collect(const QStringList& modules);

    // Detect issues
    QList<DeepinDoctor::Issue> detect(const QStringList& modules);

Q_SIGNALS:
    void collectProgress(const QString& taskId, const QString& module, double progress);
    void collectFinished(const QString& taskId, const QString& result);

private:
    QMap<QString, DeepinDoctor::ModuleInterface*> m_modules;
};

#endif // MODULE_MANAGER_H
