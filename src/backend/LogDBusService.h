#ifndef LOG_DBUS_SERVICE_H
#define LOG_DBUS_SERVICE_H

#include <QObject>
#include <QStringList>

class LogDBusService : public QObject
{
    Q_OBJECT

public:
    explicit LogDBusService(QObject* parent = nullptr);
    ~LogDBusService();

    bool registerService();

public Q_SLOTS:
    bool CheckCommand();
    QStringList ListComponents();
    bool SetDebugMode(const QStringList& components, bool enabled);
    bool IsDebugEnabled(const QString& component);
    bool ExportLogs(const QStringList& components, const QString& type, const QString& path);

Q_SIGNALS:
    void DebugModeChanged(const QString& component, bool enabled);
    void ExportProgress(const QString& component, double progress);
    void ExportFinished(bool success, const QString& path);

private:
    QString m_serviceName = "com.deepin.Doctor.LogService";
    QString m_objectPath = "/com/deepin/Doctor/Log";
};

#endif // LOG_DBUS_SERVICE_H
