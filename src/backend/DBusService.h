#ifndef DBUS_SERVICE_H
#define DBUS_SERVICE_H

#include <QObject>
#include <QJsonObject>

class ModuleManager;

class DBusService : public QObject
{
    Q_OBJECT

public:
    explicit DBusService(ModuleManager* moduleManager, QObject* parent = nullptr);
    ~DBusService();

    bool registerService();

public Q_SLOTS:
    // List available modules
    QStringList ListModules();

    // Collect information from modules
    QString Collect(const QStringList& modules);

    // Detect issues
    QString Detect(const QStringList& modules);

    // Export results
    bool Export(const QString& result, const QString& outputPath);

Q_SIGNALS:
    void CollectProgress(const QString& taskId, const QString& module, double progress);
    void CollectFinished(const QString& taskId, const QString& result);

private:
    ModuleManager* m_moduleManager;
    QString m_serviceName = "com.deepin.Doctor";
    QString m_objectPath = "/com/deepin/Doctor";
};

#endif // DBUS_SERVICE_H
