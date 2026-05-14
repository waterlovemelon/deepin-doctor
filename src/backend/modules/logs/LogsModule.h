#ifndef LOGS_MODULE_H
#define LOGS_MODULE_H

#include "ModuleInterface.h"

namespace DeepinDoctor {

class LogsModule : public ModuleInterface
{
public:
    LogsModule();
    ~LogsModule() override;

    QString name() const override { return "logs"; }
    QString description() const override { return "Application logs collector"; }
    QString version() const override { return "0.1.0"; }

    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    float progress() const override { return m_progress; }
    void cancel() override;
    bool isRunning() const override { return m_running; }

private:
    void collectApplicationLogs(QJsonObject& result);
    void collectServiceLogs(QJsonObject& result);
    void collectCrashReports(QJsonObject& result);

    QString readLogFile(const QString& path, int maxLines = 500);
    QStringList findLogFiles(const QString& dir, const QString& pattern);
    QString filterByTimeRange(const QString& logContent, int hoursBack);

    bool m_running = false;
    float m_progress = 0.0;
};

} // namespace DeepinDoctor

#endif // LOGS_MODULE_H
