#ifndef ENVIRONMENT_MODULE_H
#define ENVIRONMENT_MODULE_H

#include "ModuleInterface.h"

namespace DeepinDoctor {

class EnvironmentModule : public ModuleInterface
{
public:
    EnvironmentModule();
    ~EnvironmentModule() override;

    QString name() const override { return "environment"; }
    QString description() const override { return "System environment checker"; }
    QString version() const override { return "0.1.0"; }

    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    float progress() const override { return m_progress; }
    void cancel() override;
    bool isRunning() const override { return m_running; }

private:
    void checkPackageIntegrity(QJsonObject& result);
    void checkLibraryFiles(QJsonObject& result);
    void checkEnvironmentVariables(QJsonObject& result);
    void checkConfigFiles(QJsonObject& result);
    void checkServiceStatus(QJsonObject& result);

    QList<Issue> detectMissingPackages();
    QList<Issue> detectBrokenPackages();
    QList<Issue> detectDiskSpace();
    QList<Issue> detectPermissionIssues();
    QList<Issue> detectServiceIssues();
    QList<Issue> detectConfigIssues();
    QList<Issue> detectEnvVarIssues();
    QList<Issue> detectUpdateInterruption();
    QList<Issue> detectUserConfigIssues();
    QList<Issue> detectServiceConfigIssues();

    bool m_running = false;
    float m_progress = 0.0;
};

} // namespace DeepinDoctor

#endif // ENVIRONMENT_MODULE_H
