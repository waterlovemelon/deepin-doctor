#ifndef BACKEND_PROXY_H
#define BACKEND_PROXY_H

#include <QObject>
#include <QDBusInterface>

class BackendProxy : public QObject
{
    Q_OBJECT

public:
    explicit BackendProxy(QObject* parent = nullptr);
    ~BackendProxy();

    Q_INVOKABLE QStringList listModules();
    Q_INVOKABLE QString collect(const QStringList& modules);
    Q_INVOKABLE QString detect(const QStringList& modules);
    Q_INVOKABLE bool exportResult(const QString& result, const QString& outputPath);
    Q_INVOKABLE QString homePath() const;

Q_SIGNALS:
    void collectProgress(const QString& taskId, const QString& module, double progress);
    void collectFinished(const QString& taskId, const QString& result);
    void exportProgress(double progress);
    void exportFinished(bool success, const QString& outputPath);

private:
    QDBusInterface* m_interface;
    QString m_serviceName = "com.deepin.Doctor";
    QString m_objectPath = "/com/deepin/Doctor";
    QString m_interfaceName = "com.deepin.Doctor";
};

#endif // BACKEND_PROXY_H
