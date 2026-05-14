#ifndef NETWORK_MODULE_H
#define NETWORK_MODULE_H

#include "ModuleInterface.h"

namespace DeepinDoctor {

class NetworkModule : public ModuleInterface
{
public:
    NetworkModule();
    ~NetworkModule() override;

    QString name() const override { return "network"; }
    QString description() const override { return "Network information collector"; }
    QString version() const override { return "0.1.0"; }

    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    float progress() const override { return m_progress; }
    void cancel() override;
    bool isRunning() const override { return m_running; }

private:
    void collectNetworkStatus(QJsonObject& result);
    void collectNetworkConfig(QJsonObject& result);
    void collectNetworkLogs(QJsonObject& result);
    void collectNetworkServices(QJsonObject& result);

    QList<Issue> detectDNSIssues();
    QList<Issue> detectConnectivityIssues();
    QList<Issue> detectMissingPlugins();
    QList<Issue> detectDNSResolution();
    QList<Issue> detectIPConflict();

    bool m_running = false;
    float m_progress = 0.0;
};

} // namespace DeepinDoctor

#endif // NETWORK_MODULE_H
