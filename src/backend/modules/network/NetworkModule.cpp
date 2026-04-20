#include "NetworkModule.h"
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QJsonArray>
#include <QTextStream>

namespace DeepinDoctor {

NetworkModule::NetworkModule()
{
}

NetworkModule::~NetworkModule()
{
}

void NetworkModule::collect(QJsonObject& result)
{
    m_running = true;
    m_progress = 0.0;

    QJsonObject status, config, logs, services;

    collectNetworkStatus(status);
    m_progress = 0.25;
    result["status"] = status;

    collectNetworkConfig(config);
    m_progress = 0.5;
    result["config"] = config;

    collectNetworkLogs(logs);
    m_progress = 0.75;
    result["logs"] = logs;

    collectNetworkServices(services);
    m_progress = 1.0;
    result["services"] = services;

    m_running = false;
}

QList<Issue> NetworkModule::detect()
{
    QList<Issue> issues;

    auto dnsIssues = detectDNSIssues();
    issues.append(dnsIssues);

    auto connectivityIssues = detectConnectivityIssues();
    issues.append(connectivityIssues);

    auto pluginIssues = detectMissingPlugins();
    issues.append(pluginIssues);

    return issues;
}

void NetworkModule::cancel()
{
    m_running = false;
}

void NetworkModule::collectNetworkStatus(QJsonObject& result)
{
    // Check network interfaces
    QProcess process;
    process.start("ip", QStringList() << "addr" << "show");
    process.waitForFinished(5000);
    QString output = process.readAllStandardOutput();

    result["interfaces_raw"] = output;

    // Check if connected
    process.start("ip", QStringList() << "route");
    process.waitForFinished(5000);
    QString routes = process.readAllStandardOutput();
    result["routes"] = routes;

    bool hasDefaultRoute = routes.contains("default");
    result["has_default_route"] = hasDefaultRoute;
    result["connected"] = hasDefaultRoute;
}

void NetworkModule::collectNetworkConfig(QJsonObject& result)
{
    // Get DNS servers
    QFile resolvConf("/etc/resolv.conf");
    if (resolvConf.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&resolvConf);
        QString content = in.readAll();
        resolvConf.close();

        QStringList dnsServers;
        QStringList lines = content.split('\n');
        for (const QString& line : lines) {
            if (line.startsWith("nameserver")) {
                QStringList parts = line.split(' ', Qt::SkipEmptyParts);
                if (parts.size() >= 2) {
                    dnsServers.append(parts[1]);
                }
            }
        }
        result["dns_servers"] = QJsonArray::fromStringList(dnsServers);
    }

    // Get network manager config
    QFile networkManagerConf("/etc/NetworkManager/NetworkManager.conf");
    if (networkManagerConf.exists()) {
        if (networkManagerConf.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&networkManagerConf);
            result["networkmanager_conf"] = in.readAll();
            networkManagerConf.close();
        }
    }
}

void NetworkModule::collectNetworkLogs(QJsonObject& result)
{
    // Get recent NetworkManager logs
    QProcess process;
    process.start("journalctl", QStringList() << "-u" << "NetworkManager" << "-n" << "100" << "--no-pager");
    process.waitForFinished(10000);
    QString nmLogs = process.readAllStandardOutput();

    if (!nmLogs.isEmpty()) {
        result["networkmanager_journal"] = nmLogs;
    }

    // Get dmesg network related logs
    process.start("dmesg", QStringList());
    process.waitForFinished(5000);
    QString dmesgOutput = process.readAllStandardOutput();

    QStringList networkLines;
    QStringList lines = dmesgOutput.split('\n');
    for (const QString& line : lines) {
        if (line.contains("network", Qt::CaseInsensitive) ||
            line.contains("eth", Qt::CaseInsensitive) ||
            line.contains("wlan", Qt::CaseInsensitive) ||
            line.contains("enp", Qt::CaseInsensitive) ||
            line.contains("wlp", Qt::CaseInsensitive)) {
            networkLines.append(line);
        }
    }

    result["dmesg_network"] = networkLines.join('\n');
}

void NetworkModule::collectNetworkServices(QJsonObject& result)
{
    // Check NetworkManager status
    QProcess process;
    process.start("systemctl", QStringList() << "is-active" << "NetworkManager");
    process.waitForFinished(5000);
    QString nmStatus = process.readAllStandardOutput().trimmed();
    result["networkmanager_active"] = nmStatus;

    // Check wpa_supplicant status
    process.start("systemctl", QStringList() << "is-active" << "wpa_supplicant");
    process.waitForFinished(5000);
    QString wpaStatus = process.readAllStandardOutput().trimmed();
    result["wpa_supplicant_active"] = wpaStatus;
}

QList<Issue> NetworkModule::detectDNSIssues()
{
    QList<Issue> issues;

    // Check if DNS servers are configured
    QFile resolvConf("/etc/resolv.conf");
    if (resolvConf.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&resolvConf);
        QString content = in.readAll();
        resolvConf.close();

        if (!content.contains("nameserver")) {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = "No DNS servers configured";
            issue.description = "/etc/resolv.conf does not contain any nameserver entries";
            issue.solution = "Add DNS servers to /etc/resolv.conf or configure NetworkManager DNS settings";
            issues.append(issue);
        }
    }

    return issues;
}

QList<Issue> NetworkModule::detectConnectivityIssues()
{
    QList<Issue> issues;

    // Test ping to gateway (if route exists)
    QProcess process;
    process.start("ip", QStringList() << "route");
    process.waitForFinished(5000);
    QString routes = process.readAllStandardOutput();

    if (routes.contains("default")) {
        QStringList parts = routes.split('\n')[0].split(' ');
        int viaIndex = parts.indexOf("via");
        if (viaIndex >= 0 && viaIndex + 1 < parts.size()) {
            QString gateway = parts[viaIndex + 1];

            // Ping gateway
            process.start("ping", QStringList() << "-c" << "1" << "-W" << "2" << gateway);
            process.waitForFinished(5000);
            int exitCode = process.exitCode();

            if (exitCode != 0) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = "Cannot reach gateway";
                issue.description = QString("Failed to ping gateway %1").arg(gateway);
                issue.solution = "Check network cable connection or WiFi signal strength";
                issues.append(issue);
            }
        }
    }

    return issues;
}

QList<Issue> NetworkModule::detectMissingPlugins()
{
    QList<Issue> issues;

    // Check for network plugins in dde-dock
    QDir dockPluginDir("/usr/lib/dde-dock/plugins");
    if (dockPluginDir.exists()) {
        QStringList plugins = dockPluginDir.entryList(QStringList() << "*network*", QDir::Files);
        if (plugins.isEmpty()) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Network plugin missing from dock";
            issue.description = "No network plugin found in /usr/lib/dde-dock/plugins";
            issue.solution = "Install dde-daemon package or check plugin installation";
            issues.append(issue);
        }
    }

    // Check for network plugins in dde-control-center
    QDir ccPluginDir("/usr/lib/dde-control-center/modules");
    if (ccPluginDir.exists()) {
        QStringList plugins = ccPluginDir.entryList(QStringList() << "*network*", QDir::Files);
        if (plugins.isEmpty()) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Network plugin missing from control center";
            issue.description = "No network plugin found in /usr/lib/dde-control-center/modules";
            issue.solution = "Install dde-control-center network module";
            issues.append(issue);
        }
    }

    return issues;
}

} // namespace DeepinDoctor
