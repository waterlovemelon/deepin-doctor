#ifndef LOG_BACKEND_PROXY_H
#define LOG_BACKEND_PROXY_H

#include <QObject>
#include <QDBusInterface>

class LogBackendProxy : public QObject
{
    Q_OBJECT

public:
    explicit LogBackendProxy(QObject* parent = nullptr);
    ~LogBackendProxy();

    Q_INVOKABLE bool checkCommand();
    Q_INVOKABLE QStringList listComponents();
    Q_INVOKABLE bool setDebugMode(const QStringList& components, bool enabled);
    Q_INVOKABLE bool isDebugEnabled(const QString& component);
    Q_INVOKABLE bool exportLogs(const QStringList& components, const QString& type, const QString& path);

Q_SIGNALS:
    void debugModeChanged(const QString& component, bool enabled);
    void exportProgress(const QString& component, double progress);
    void exportFinished(bool success, const QString& path);

private:
    QDBusInterface* m_interface;
    QString m_serviceName = "com.deepin.Doctor.LogService";
    QString m_objectPath = "/com/deepin/Doctor/Log";
    QString m_interfaceName = "com.deepin.Doctor.LogService";
};

#endif // LOG_BACKEND_PROXY_H
