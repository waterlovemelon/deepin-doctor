#ifndef SYSTEM_MODULE_H
#define SYSTEM_MODULE_H

#include "ModuleInterface.h"

namespace DeepinDoctor {

class SystemModule : public ModuleInterface
{
public:
    SystemModule();
    ~SystemModule() override;

    QString name() const override { return "system"; }
    QString description() const override { return "System information collector"; }
    QString version() const override { return "0.1.0"; }

    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    float progress() const override { return m_progress; }
    void cancel() override;
    bool isRunning() const override { return m_running; }

private:
    void collectHardwareInfo(QJsonObject& result);
    void collectSystemInfo(QJsonObject& result);
    void collectSystemLogs(QJsonObject& result);

    bool m_running = false;
    float m_progress = 0.0;
};

} // namespace DeepinDoctor

#endif // SYSTEM_MODULE_H
