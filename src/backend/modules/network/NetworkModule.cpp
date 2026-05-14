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

    auto dnsResIssues = detectDNSResolution();
    issues.append(dnsResIssues);

    auto ipConflictIssues = detectIPConflict();
    issues.append(ipConflictIssues);

    auto driverIssues = detectDriverIssues();
    issues.append(driverIssues);

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

QList<Issue> NetworkModule::detectDNSResolution()
{
    QList<Issue> issues;

    // Read DNS servers from resolv.conf
    QFile resolvConf("/etc/resolv.conf");
    QStringList dnsServers;
    if (resolvConf.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&resolvConf);
        QStringList lines = in.readAll().split('\n');
        resolvConf.close();

        for (const QString& line : lines) {
            if (line.startsWith("nameserver")) {
                QStringList parts = line.split(' ', Qt::SkipEmptyParts);
                if (parts.size() >= 2) {
                    dnsServers.append(parts[1]);
                }
            }
        }
    }

    if (dnsServers.isEmpty()) {
        return issues;
    }

    // Test DNS resolution using dig (or nslookup as fallback)
    QProcess process;
    process.start("which", QStringList() << "dig");
    process.waitForFinished(3000);
    bool hasDig = process.exitCode() == 0;

    QString testDomain = "www.deepin.org";

    if (hasDig) {
        for (const QString& server : dnsServers) {
            process.start("dig", QStringList() << "+short" << "+time=3" << "+tries=1"
                          << ("@" + server) << testDomain << "A");
            process.waitForFinished(10000);
            QString output = process.readAllStandardOutput().trimmed();
            int exitCode = process.exitCode();

            if (exitCode != 0 || output.isEmpty()) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = QString("DNS resolution failed: %1").arg(server);
                issue.description = QString("Cannot resolve %1 via DNS server %2")
                    .arg(testDomain).arg(server);
                issue.solution = "Check DNS server configuration or network connectivity";
                issues.append(issue);
            }
        }
    } else {
        // Fallback to nslookup
        for (const QString& server : dnsServers) {
            process.start("nslookup", QStringList() << "-timeout=3" << testDomain << server);
            process.waitForFinished(10000);
            QString output = process.readAllStandardOutput();
            int exitCode = process.exitCode();

            if (exitCode != 0 || output.contains("server can't find")) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = QString("DNS resolution failed: %1").arg(server);
                issue.description = QString("Cannot resolve %1 via DNS server %2")
                    .arg(testDomain).arg(server);
                issue.solution = "Check DNS server configuration or network connectivity";
                issues.append(issue);
            }
        }
    }

    return issues;
}

QList<Issue> NetworkModule::detectIPConflict()
{
    QList<Issue> issues;

    // Get local IP addresses
    QProcess process;
    process.start("ip", QStringList() << "-4" << "addr" << "show");
    process.waitForFinished(5000);
    QString addrOutput = process.readAllStandardOutput();

    QStringList localIPs;
    QStringList lines = addrOutput.split('\n');
    for (const QString& line : lines) {
        if (line.contains("inet ") && !line.contains("127.0.0.1")) {
            QStringList parts = line.trimmed().split(QRegExp("\\s+"));
            for (const QString& part : parts) {
                if (part.contains("/")) {
                    localIPs.append(part.split('/').first());
                }
            }
        }
    }

    if (localIPs.isEmpty()) {
        return issues;
    }

    // Check if arping is available
    process.start("which", QStringList() << "arping");
    process.waitForFinished(3000);
    bool hasArping = process.exitCode() == 0;

    if (!hasArping) {
        return issues;
    }

    // Get default interface
    process.start("ip", QStringList() << "route" << "show" << "default");
    process.waitForFinished(5000);
    QString routeOutput = process.readAllStandardOutput().trimmed();
    QString iface;
    if (routeOutput.contains("dev")) {
        QStringList parts = routeOutput.split(QRegExp("\\s+"));
        int devIdx = parts.indexOf("dev");
        if (devIdx >= 0 && devIdx + 1 < parts.size()) {
            iface = parts[devIdx + 1];
        }
    }

    // Use arping to detect duplicate IPs on local network
    for (const QString& ip : localIPs) {
        QStringList args;
        args << "-c" << "1" << "-w" << "2";
        if (!iface.isEmpty()) {
            args << "-I" << iface;
        }
        args << ip;

        process.start("arping", args);
        process.waitForFinished(10000);
        QString output = process.readAllStandardOutput();

        // arping returns multiple replies if there's a conflict
        if (output.contains("Duplicate")) {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = QString("IP conflict detected: %1").arg(ip);
            issue.description = QString("IP address %1 is used by multiple devices on the network").arg(ip);
            issue.solution = "Change the IP address or resolve the conflict with the other device";
            issues.append(issue);
        }
    }

    return issues;
}

QList<Issue> NetworkModule::detectDriverIssues()
{
    QList<Issue> issues;

    QProcess process;

    // Check dmesg for network driver errors
    process.start("dmesg", QStringList());
    process.waitForFinished(5000);
    QString dmesgOutput = process.readAllStandardOutput();

    QStringList errorPatterns = {
        "firmware failed",
        "driver crashed",
        "link is down",
        "reset adapter",
        "hardware error",
        "PHY",
        "timeout"
    };

    QStringList driverErrors;
    QStringList lines = dmesgOutput.split('\n');
    for (const QString& line : lines) {
        if (line.contains("eth", Qt::CaseInsensitive) ||
            line.contains("enp", Qt::CaseInsensitive) ||
            line.contains("wlp", Qt::CaseInsensitive) ||
            line.contains("wlan", Qt::CaseInsensitive) ||
            line.contains("network", Qt::CaseInsensitive)) {

            for (const QString& pattern : errorPatterns) {
                if (line.contains(pattern, Qt::CaseInsensitive)) {
                    driverErrors.append(line.trimmed());
                    break;
                }
            }
        }
    }

    if (!driverErrors.isEmpty()) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "Network driver errors detected";
        issue.description = QString("Found %1 network driver related errors in dmesg:\n%2")
            .arg(driverErrors.size())
            .arg(driverErrors.mid(0, 5).join("\n"));
        issue.solution = "Check NIC hardware, update drivers, or replace the network adapter";
        issues.append(issue);
    }

    // Check link status for each interface
    process.start("ip", QStringList() << "link" << "show");
    process.waitForFinished(5000);
    QString linkOutput = process.readAllStandardOutput();

    QStringList linkLines = linkOutput.split('\n');
    QString currentIface;
    for (const QString& line : linkLines) {
        if (line.contains(": <")) {
            QStringList parts = line.split(':');
            if (parts.size() >= 2) {
                currentIface = parts[1].trimmed().split('@').first().trimmed();
            }
            if (currentIface != "lo" && !line.contains("LOWER_UP")) {
                // Interface exists but link is not up
                if (!currentIface.isEmpty()) {
                    Issue issue;
                    issue.level = Issue::Info;
                    issue.title = QString("Interface link down: %1").arg(currentIface);
                    issue.description = QString("Network interface %1 does not have link up").arg(currentIface);
                    issue.solution = "Check cable connection or WiFi signal";
                    issues.append(issue);
                }
            }
        }
    }

    return issues;
}

} // namespace DeepinDoctor
