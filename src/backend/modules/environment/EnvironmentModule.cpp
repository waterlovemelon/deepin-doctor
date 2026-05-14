#include "EnvironmentModule.h"
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QJsonArray>
#include <QStandardPaths>

namespace DeepinDoctor {

EnvironmentModule::EnvironmentModule()
{
}

EnvironmentModule::~EnvironmentModule()
{
}

void EnvironmentModule::collect(QJsonObject& result)
{
    m_running = true;
    m_progress = 0.0;

    QJsonObject packages, libs, envVars, configs, services;

    checkPackageIntegrity(packages);
    m_progress = 0.2;
    result["packages"] = packages;

    checkLibraryFiles(libs);
    m_progress = 0.4;
    result["libraries"] = libs;

    checkEnvironmentVariables(envVars);
    m_progress = 0.6;
    result["environment_variables"] = envVars;

    checkConfigFiles(configs);
    m_progress = 0.8;
    result["config_files"] = configs;

    checkServiceStatus(services);
    m_progress = 1.0;
    result["services"] = services;

    m_running = false;
}

QList<Issue> EnvironmentModule::detect()
{
    QList<Issue> issues;

    issues.append(detectMissingPackages());
    issues.append(detectBrokenPackages());
    issues.append(detectDiskSpace());
    issues.append(detectPermissionIssues());
    issues.append(detectServiceIssues());
    issues.append(detectConfigIssues());
    issues.append(detectEnvVarIssues());
    issues.append(detectUpdateInterruption());

    return issues;
}

void EnvironmentModule::cancel()
{
    m_running = false;
}

void EnvironmentModule::checkPackageIntegrity(QJsonObject& result)
{
    QProcess process;

    // Check if dpkg is available
    process.start("which", QStringList() << "dpkg");
    process.waitForFinished(5000);
    bool hasDpkg = process.exitCode() == 0;

    if (hasDpkg) {
        // Get package verification status
        process.start("dpkg", QStringList() << "-C");
        process.waitForFinished(10000);
        QString verifyOutput = process.readAllStandardOutput();

        if (verifyOutput.isEmpty()) {
            result["status"] = "ok";
            result["message"] = "All packages are intact";
        } else {
            result["status"] = "warning";
            result["broken_packages"] = QJsonArray::fromStringList(verifyOutput.split('\n'));
        }

        // Check for incomplete installations
        process.start("dpkg", QStringList() << "--audit");
        process.waitForFinished(10000);
        QString auditOutput = process.readAllStandardOutput();

        if (!auditOutput.isEmpty()) {
            result["audit_result"] = auditOutput;
        }

        // List recently installed/removed packages
        process.start("grep", QStringList() << "install\\|remove\\|upgrade" << "/var/log/dpkg.log");
        process.waitForFinished(5000);
        QString dpkgLog = process.readAllStandardOutput();
        QStringList recentActions = dpkgLog.split('\n').mid(-50); // Last 50 actions
        result["recent_package_actions"] = QJsonArray::fromStringList(recentActions);
    } else {
        // RPM-based system
        process.start("rpm", QStringList() << "-Va");
        process.waitForFinished(10000);
        QString rpmVerify = process.readAllStandardOutput();

        if (rpmVerify.isEmpty()) {
            result["status"] = "ok";
        } else {
            result["status"] = "warning";
            result["verification_output"] = rpmVerify;
        }
    }

    // Check for lock files
    QStringList lockFiles = {
        "/var/lib/dpkg/lock",
        "/var/lib/dpkg/lock-frontend",
        "/var/lib/apt/lists/lock",
        "/var/cache/apt/archives/lock"
    };

    QJsonArray locks;
    for (const QString& lockFile : lockFiles) {
        QFile lock(lockFile);
        if (lock.exists()) {
            QJsonObject lockInfo;
            lockInfo["path"] = lockFile;
            lockInfo["size"] = (qint64)lock.size();

            // Check if process is holding the lock
            process.start("fuser", QStringList() << lockFile);
            process.waitForFinished(5000);
            QString holder = process.readAllStandardOutput().trimmed();
            lockInfo["held_by"] = holder;

            locks.append(lockInfo);
        }
    }

    result["lock_files"] = locks;
}

void EnvironmentModule::checkLibraryFiles(QJsonObject& result)
{
    // Check LD_LIBRARY_PATH
    QString ldLibraryPath = qEnvironmentVariable("LD_LIBRARY_PATH");
    if (!ldLibraryPath.isEmpty()) {
        result["ld_library_path"] = ldLibraryPath;
    }

    // Check critical libraries
    QStringList criticalLibs = {
        "libc.so.6",
        "libpthread.so.0",
        "libQt5Core.so.5",
        "libQt5Gui.so.5",
        "libQt5Widgets.so.5",
        "libdde-core.so"
    };

    QJsonObject libStatus;
    for (const QString& lib : criticalLibs) {
        QProcess process;
        process.start("ldconfig", QStringList() << "-p");
        process.waitForFinished(5000);
        QString output = process.readAllStandardOutput();

        bool found = output.contains(lib);
        libStatus[lib] = found;

        if (found) {
            // Extract full path
            QStringList lines = output.split('\n');
            for (const QString& line : lines) {
                if (line.contains(lib)) {
                    QStringList parts = line.split("=>");
                    if (parts.size() >= 2) {
                        libStatus[lib + "_path"] = parts[1].trimmed().split(' ').first();
                    }
                    break;
                }
            }
        }
    }

    result["critical_libraries"] = libStatus;
}

void EnvironmentModule::checkEnvironmentVariables(QJsonObject& result)
{
    // Collect important environment variables
    QStringList importantVars = {
        "PATH",
        "LD_LIBRARY_PATH",
        "HOME",
        "USER",
        "SHELL",
        "DISPLAY",
        "XDG_SESSION_TYPE",
        "XDG_CURRENT_DESKTOP",
        "LANG",
        "LANGUAGE",
        "LC_ALL",
        "QT_QPA_PLATFORM",
        "QT_STYLE_OVERRIDE"
    };

    for (const QString& var : importantVars) {
        QByteArray value = qgetenv(var.toUtf8());
        if (!value.isEmpty()) {
            result[var] = QString::fromUtf8(value);
        }
    }

    // Check for invalid paths in PATH (don't exist or no permission)
    QString pathEnv = qEnvironmentVariable("PATH");
    if (!pathEnv.isEmpty()) {
        QStringList paths = pathEnv.split(':');
        QSet<QString> uniquePaths;
        QJsonArray duplicatePaths;
        QJsonArray invalidPaths;

        for (const QString& path : paths) {
            if (path.isEmpty()) continue;

            // Check for duplicate paths
            if (uniquePaths.contains(path)) {
                duplicatePaths.append(path);
            } else {
                uniquePaths.insert(path);

                // Check if path exists and is accessible
                QDir dir(path);
                if (!dir.exists()) {
                    QJsonObject invalidPath;
                    invalidPath["path"] = path;
                    invalidPath["reason"] = "Directory does not exist";
                    invalidPaths.append(invalidPath);
                } else {
                    QFileInfo pathInfo(path);
                    if (!pathInfo.isReadable()) {
                        QJsonObject invalidPath;
                        invalidPath["path"] = path;
                        invalidPath["reason"] = "No read permission";
                        invalidPaths.append(invalidPath);
                    }
                }
            }
        }

        if (!duplicatePaths.isEmpty()) {
            result["duplicate_paths_in_path"] = duplicatePaths;
        }

        if (!invalidPaths.isEmpty()) {
            result["invalid_paths_in_path"] = invalidPaths;
        }
    }

    // Check for duplicate paths in LD_LIBRARY_PATH
    QString ldLibraryPath = qEnvironmentVariable("LD_LIBRARY_PATH");
    if (!ldLibraryPath.isEmpty()) {
        QStringList ldPaths = ldLibraryPath.split(':');
        QSet<QString> uniqueLdPaths;
        QJsonArray duplicateLdPaths;

        for (const QString& path : ldPaths) {
            if (path.isEmpty()) continue;

            if (uniqueLdPaths.contains(path)) {
                duplicateLdPaths.append(path);
            } else {
                uniqueLdPaths.insert(path);
            }
        }

        if (!duplicateLdPaths.isEmpty()) {
            result["duplicate_paths_in_ld_library_path"] = duplicateLdPaths;
        }
    }

    // Check for LANG vs LC_ALL conflicts
    QString lang = qEnvironmentVariable("LANG");
    QString lcAll = qEnvironmentVariable("LC_ALL");

    if (!lang.isEmpty() && !lcAll.isEmpty()) {
        if (lang != lcAll) {
            QJsonObject conflict;
            conflict["LANG"] = lang;
            conflict["LC_ALL"] = lcAll;
            conflict["warning"] = "LANG and LC_ALL are different, LC_ALL will override LANG";
            result["locale_conflict"] = conflict;
        }
    }
}

void EnvironmentModule::checkConfigFiles(QJsonObject& result)
{
    // Check important config directories
    QStringList configDirs = {
        "/etc",
        QDir::homePath() + "/.config",
        QDir::homePath() + "/.local/share"
    };

    for (const QString& dir : configDirs) {
        QDir d(dir);
        if (d.exists()) {
            QJsonObject dirInfo;
            dirInfo["exists"] = true;
            dirInfo["writable"] = QFileInfo(dir).isWritable();
            result[dir] = dirInfo;
        }
    }

    // Check /etc/hosts
    QFile hostsFile("/etc/hosts");
    if (hostsFile.exists()) {
        QJsonObject hostsInfo;
        hostsInfo["exists"] = true;
        hostsInfo["readable"] = hostsFile.open(QIODevice::ReadOnly);
        if (hostsInfo["readable"].toBool()) {
            hostsFile.close();
            hostsInfo["size"] = (qint64)hostsFile.size();
        }
        result["/etc/hosts"] = hostsInfo;
    } else {
        QJsonObject hostsInfo;
        hostsInfo["exists"] = false;
        result["/etc/hosts"] = hostsInfo;
    }

    // Check /etc/fstab
    QFile fstabFile("/etc/fstab");
    if (fstabFile.exists()) {
        QJsonObject fstabInfo;
        fstabInfo["exists"] = true;
        fstabInfo["readable"] = fstabFile.open(QIODevice::ReadOnly);

        if (fstabInfo["readable"].toBool()) {
            // Basic validation: check if file is not empty
            QString content = fstabFile.readAll();
            fstabFile.close();

            fstabInfo["size"] = content.size();
            fstabInfo["valid"] = content.size() > 0;

            // Count non-comment, non-empty lines
            QStringList lines = content.split('\n');
            int validLines = 0;
            for (const QString& line : lines) {
                QString trimmed = line.trimmed();
                if (!trimmed.isEmpty() && !trimmed.startsWith('#')) {
                    validLines++;
                }
            }
            fstabInfo["valid_entries"] = validLines;
        }
        result["/etc/fstab"] = fstabInfo;
    } else {
        QJsonObject fstabInfo;
        fstabInfo["exists"] = false;
        fstabInfo["valid"] = false;
        result["/etc/fstab"] = fstabInfo;
    }

    // Check /etc/apt/sources.list
    QFile sourcesListFile("/etc/apt/sources.list");
    QJsonObject sourcesListInfo;
    sourcesListInfo["exists"] = sourcesListFile.exists();
    if (sourcesListInfo["exists"].toBool()) {
        sourcesListInfo["readable"] = sourcesListFile.open(QIODevice::ReadOnly);
        if (sourcesListInfo["readable"].toBool()) {
            sourcesListFile.close();
            sourcesListInfo["size"] = (qint64)sourcesListFile.size();
        }
    }
    result["/etc/apt/sources.list"] = sourcesListInfo;

    // Check ~/.config/autostart directory permissions
    QString autostartDir = QDir::homePath() + "/.config/autostart";
    QDir autostart(autostartDir);
    QJsonObject autostartInfo;
    autostartInfo["exists"] = autostart.exists();

    if (autostart.exists()) {
        QFileInfo autostartInfoFile(autostartDir);
        autostartInfo["readable"] = autostartInfoFile.isReadable();
        autostartInfo["writable"] = autostartInfoFile.isWritable();
        autostartInfo["executable"] = autostartInfoFile.isExecutable();

        // List autostart entries
        QStringList autostartEntries = autostart.entryList(QStringList() << "*.desktop", QDir::Files);
        autostartInfo["entry_count"] = autostartEntries.size();
        autostartInfo["entries"] = QJsonArray::fromStringList(autostartEntries);
    }
    result["autostart_directory"] = autostartInfo;

    // Check DDE specific configs
    QString ddeConfigPath = QDir::homePath() + "/.config/deepin";
    QDir ddeConfigDir(ddeConfigPath);
    if (ddeConfigDir.exists()) {
        QStringList configFiles = ddeConfigDir.entryList(QDir::Files);
        result["dde_config_files"] = QJsonArray::fromStringList(configFiles);
    }
}

void EnvironmentModule::checkServiceStatus(QJsonObject& result)
{
    QProcess process;

    // Check if systemd is running
    process.start("pidof", QStringList() << "systemd");
    process.waitForFinished(5000);
    bool systemdRunning = process.exitCode() == 0;

    result["systemd_running"] = systemdRunning;

    if (!systemdRunning) {
        result["status"] = "warning";
        result["message"] = "systemd is not running";
        return;
    }

    // Check for failed services
    process.start("systemctl", QStringList() << "list-units" << "--state=failed" << "--no-legend");
    process.waitForFinished(10000);
    QString failedOutput = process.readAllStandardOutput();

    QJsonArray failedServices;
    if (!failedOutput.isEmpty()) {
        QStringList lines = failedOutput.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 1) {
                QJsonObject failedService;
                failedService["name"] = parts[0];
                if (parts.size() >= 4) {
                    failedService["load"] = parts[1];
                    failedService["active"] = parts[2];
                    failedService["sub"] = parts[3];
                }
                failedServices.append(failedService);
            }
        }
    }

    result["failed_services"] = failedServices;
    result["failed_service_count"] = failedServices.size();

    // Check key systemd services
    QStringList keyServices = {
        "dbus.service",
        "NetworkManager.service",
        "systemd-logind.service",
        "polkit.service",
        "cron.service"
    };

    QJsonObject serviceStatus;
    for (const QString& service : keyServices) {
        process.start("systemctl", QStringList() << "is-active" << service);
        process.waitForFinished(5000);
        QString status = process.readAllStandardOutput().trimmed();

        QJsonObject serviceInfo;
        serviceInfo["active"] = (status == "active");

        // Get more details
        process.start("systemctl", QStringList() << "is-enabled" << service);
        process.waitForFinished(5000);
        QString enabled = process.readAllStandardOutput().trimmed();
        serviceInfo["enabled"] = (enabled == "enabled" || enabled == "static");

        serviceStatus[service] = serviceInfo;
    }

    result["key_services"] = serviceStatus;

    // Overall status
    if (failedServices.size() > 0) {
        result["status"] = "warning";
        result["message"] = QString("%1 failed service(s) detected").arg(failedServices.size());
    } else {
        result["status"] = "ok";
        result["message"] = "All services are running normally";
    }
}

QList<Issue> EnvironmentModule::detectMissingPackages()
{
    QList<Issue> issues;

    // Check for essential packages
    QStringList essentialPackages = {
        "dde-desktop",
        "dde-daemon",
        "deepin-anything",
        "startdde"
    };

    QProcess process;
    for (const QString& pkg : essentialPackages) {
        process.start("dpkg", QStringList() << "-s" << pkg);
        process.waitForFinished(5000);
        QString output = process.readAllStandardOutput();

        if (!output.contains("Status: install ok installed")) {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = QString("Missing essential package: %1").arg(pkg);
            issue.description = QString("Package %1 is not installed or not properly configured").arg(pkg);
            issue.solution = QString("Install package: sudo apt install %1").arg(pkg);
            issues.append(issue);
        }
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectBrokenPackages()
{
    QList<Issue> issues;

    QProcess process;
    process.start("dpkg", QStringList() << "-C");
    process.waitForFinished(10000);
    QString output = process.readAllStandardOutput();

    if (!output.isEmpty()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "Broken packages detected";
        issue.description = "Some packages are in a broken state:\n" + output;
        issue.solution = "Run: sudo dpkg --configure -a";
        issues.append(issue);
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectDiskSpace()
{
    QList<Issue> issues;

    QProcess process;
    process.start("df", QStringList() << "-h");
    process.waitForFinished(5000);
    QString output = process.readAllStandardOutput();

    QStringList lines = output.split('\n');
    for (const QString& line : lines.mid(1)) { // Skip header
        QStringList parts = line.split(QRegExp("\\s+"));
        if (parts.size() >= 5) {
            QString usage = parts[4].replace('%', "");
            bool ok;
            int usagePercent = usage.toInt(&ok);

            if (ok && usagePercent > 90) {
                Issue issue;
                issue.level = usagePercent > 95 ? Issue::Error : Issue::Warning;
                issue.title = QString("Disk almost full: %1").arg(parts[5]);
                issue.description = QString("Mount point %1 is %2% full").arg(parts[5]).arg(usagePercent);
                issue.solution = "Clean up disk space or expand partition";
                issues.append(issue);
            }
        }
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectPermissionIssues()
{
    QList<Issue> issues;

    // Check home directory permissions
    QString homeDir = QDir::homePath();
    QFileInfo homeInfo(homeDir);

    if (!homeInfo.isReadable() || !homeInfo.isWritable()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "Home directory permission issue";
        issue.description = QString("Home directory %1 has incorrect permissions").arg(homeDir);
        issue.solution = "Check and fix home directory permissions";
        issues.append(issue);
    }

    // Check .config directory
    QString configDir = homeDir + "/.config";
    QFileInfo configInfo(configDir);

    if (configInfo.exists() && (!configInfo.isReadable() || !configInfo.isWritable())) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = ".config directory permission issue";
        issue.description = QString("Config directory %1 has incorrect permissions").arg(configDir);
        issue.solution = "Fix permissions: chmod 755 " + configDir;
        issues.append(issue);
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectServiceIssues()
{
    QList<Issue> issues;

    QProcess process;

    // Check if systemd is running
    process.start("pidof", QStringList() << "systemd");
    process.waitForFinished(5000);
    bool systemdRunning = process.exitCode() == 0;

    if (!systemdRunning) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "systemd is not running";
        issue.description = "System is not using systemd as init system";
        issue.solution = "Check system initialization configuration";
        issues.append(issue);
        return issues;
    }

    // Check for failed services
    process.start("systemctl", QStringList() << "list-units" << "--state=failed" << "--no-legend");
    process.waitForFinished(10000);
    QString failedOutput = process.readAllStandardOutput();

    if (!failedOutput.isEmpty()) {
        QStringList lines = failedOutput.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 1) {
                Issue issue;
                issue.level = Issue::Error;
                issue.title = QString("Failed service: %1").arg(parts[0]);
                issue.description = QString("Service %1 is in failed state").arg(parts[0]);

                // Get more details
                process.start("systemctl", QStringList() << "status" << parts[0]);
                process.waitForFinished(5000);
                QString statusOutput = process.readAllStandardOutput();
                issue.description += "\n\n" + statusOutput;

                issue.solution = QString("Check service status: systemctl status %1\nRestart service: systemctl restart %1").arg(parts[0]);
                issues.append(issue);
            }
        }
    }

    // Check critical services
    QStringList criticalServices = {
        "dbus.service",
        "systemd-logind.service"
    };

    for (const QString& service : criticalServices) {
        process.start("systemctl", QStringList() << "is-active" << service);
        process.waitForFinished(5000);
        QString status = process.readAllStandardOutput().trimmed();

        if (status != "active") {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = QString("Critical service not active: %1").arg(service);
            issue.description = QString("Service %1 is not running (status: %2)").arg(service).arg(status);
            issue.solution = QString("Restart service: systemctl restart %1").arg(service);
            issues.append(issue);
        }
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectConfigIssues()
{
    QList<Issue> issues;

    // Check /etc/hosts
    QFile hostsFile("/etc/hosts");
    if (!hostsFile.exists()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "/etc/hosts file missing";
        issue.description = "The /etc/hosts file does not exist, which may cause network resolution issues";
        issue.solution = "Create /etc/hosts file with basic configuration";
        issues.append(issue);
    } else if (!hostsFile.open(QIODevice::ReadOnly)) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "/etc/hosts not readable";
        issue.description = "The /etc/hosts file exists but cannot be read";
        issue.solution = "Check file permissions: ls -la /etc/hosts";
        issues.append(issue);
    } else {
        hostsFile.close();
    }

    // Check /etc/fstab
    QFile fstabFile("/etc/fstab");
    if (!fstabFile.exists()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "/etc/fstab file missing";
        issue.description = "The /etc/fstab file does not exist, which may cause mount issues";
        issue.solution = "Create /etc/fstab file with proper mount configuration";
        issues.append(issue);
    } else if (fstabFile.open(QIODevice::ReadOnly)) {
        QString content = fstabFile.readAll();
        fstabFile.close();

        // Check if fstab is empty or only contains comments
        bool hasValidEntries = false;
        QStringList lines = content.split('\n');
        for (const QString& line : lines) {
            QString trimmed = line.trimmed();
            if (!trimmed.isEmpty() && !trimmed.startsWith('#')) {
                hasValidEntries = true;
                break;
            }
        }

        if (!hasValidEntries) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "/etc/fstab has no valid entries";
            issue.description = "The /etc/fstab file exists but contains no valid mount entries";
            issue.solution = "Add proper mount entries to /etc/fstab";
            issues.append(issue);
        }
    } else {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "/etc/fstab not readable";
        issue.description = "The /etc/fstab file exists but cannot be read";
        issue.solution = "Check file permissions: ls -la /etc/fstab";
        issues.append(issue);
    }

    // Check /etc/apt/sources.list (for Debian/Ubuntu systems)
    QFile sourcesListFile("/etc/apt/sources.list");
    if (!sourcesListFile.exists()) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "/etc/apt/sources.list missing";
        issue.description = "APT sources list file does not exist";
        issue.solution = "Create /etc/apt/sources.list or check /etc/apt/sources.list.d/";
        issues.append(issue);
    }

    // Check ~/.config/autostart directory
    QString autostartDir = QDir::homePath() + "/.config/autostart";
    QDir autostart(autostartDir);

    if (autostart.exists()) {
        QFileInfo autostartInfo(autostartDir);
        if (!autostartInfo.isReadable() || !autostartInfo.isExecutable()) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Autostart directory permission issue";
            issue.description = QString("Directory %1 has incorrect permissions").arg(autostartDir);
            issue.solution = QString("Fix permissions: chmod 755 %1").arg(autostartDir);
            issues.append(issue);
        }
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectEnvVarIssues()
{
    QList<Issue> issues;

    // Check for invalid paths in PATH
    QString pathEnv = qEnvironmentVariable("PATH");
    if (!pathEnv.isEmpty()) {
        QStringList paths = pathEnv.split(':');
        QStringList invalidPaths;

        for (const QString& path : paths) {
            if (path.isEmpty()) continue;

            QDir dir(path);
            if (!dir.exists()) {
                invalidPaths.append(path + " (does not exist)");
            } else {
                QFileInfo pathInfo(path);
                if (!pathInfo.isReadable()) {
                    invalidPaths.append(path + " (no read permission)");
                }
            }
        }

        if (!invalidPaths.isEmpty()) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Invalid paths in PATH";
            issue.description = "The PATH environment variable contains invalid paths:\n" + invalidPaths.join("\n");
            issue.solution = "Remove or fix invalid paths in PATH environment variable";
            issues.append(issue);
        }

        // Check for duplicate paths in PATH
        QSet<QString> uniquePaths;
        QStringList duplicatePaths;
        for (const QString& path : paths) {
            if (!path.isEmpty() && uniquePaths.contains(path)) {
                duplicatePaths.append(path);
            }
            uniquePaths.insert(path);
        }

        if (!duplicatePaths.isEmpty()) {
            Issue issue;
            issue.level = Issue::Info;
            issue.title = "Duplicate paths in PATH";
            issue.description = "The PATH environment variable contains duplicate paths:\n" + duplicatePaths.join("\n");
            issue.solution = "Remove duplicate entries from PATH";
            issues.append(issue);
        }
    }

    // Check for duplicate paths in LD_LIBRARY_PATH
    QString ldLibraryPath = qEnvironmentVariable("LD_LIBRARY_PATH");
    if (!ldLibraryPath.isEmpty()) {
        QStringList ldPaths = ldLibraryPath.split(':');
        QSet<QString> uniqueLdPaths;
        QStringList duplicateLdPaths;

        for (const QString& path : ldPaths) {
            if (!path.isEmpty() && uniqueLdPaths.contains(path)) {
                duplicateLdPaths.append(path);
            }
            uniqueLdPaths.insert(path);
        }

        if (!duplicateLdPaths.isEmpty()) {
            Issue issue;
            issue.level = Issue::Info;
            issue.title = "Duplicate paths in LD_LIBRARY_PATH";
            issue.description = "The LD_LIBRARY_PATH environment variable contains duplicate paths:\n" + duplicateLdPaths.join("\n");
            issue.solution = "Remove duplicate entries from LD_LIBRARY_PATH";
            issues.append(issue);
        }
    }

    // Check for LANG vs LC_ALL conflicts
    QString lang = qEnvironmentVariable("LANG");
    QString lcAll = qEnvironmentVariable("LC_ALL");

    if (!lang.isEmpty() && !lcAll.isEmpty() && lang != lcAll) {
        Issue issue;
        issue.level = Issue::Info;
        issue.title = "LANG and LC_ALL conflict";
        issue.description = QString("LANG=%1 and LC_ALL=%2 are different. LC_ALL will override LANG settings.")
                                .arg(lang).arg(lcAll);
        issue.solution = "Ensure LANG and LC_ALL are consistent, or unset LC_ALL if you want LANG to take effect";
        issues.append(issue);
    }

    return issues;
}

QList<Issue> EnvironmentModule::detectUpdateInterruption()
{
    QList<Issue> issues;

    QProcess process;

    // Check dpkg for packages in half-installed / config-files state
    process.start("dpkg", QStringList() << "-l");
    process.waitForFinished(10000);
    QString dpkgOutput = process.readAllStandardOutput();

    QStringList halfInstalled;
    QStringList needsConfig;
    QStringList lines = dpkgOutput.split('\n');
    for (const QString& line : lines) {
        if (line.startsWith("iU") || line.startsWith("iF")) {
            // iU = half-installed, unpacked; iF = half-installed, config-files
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) {
                halfInstalled.append(parts[1]);
            }
        }
        if (line.startsWith("cF")) {
            // cF = config-files, failed config
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) {
                needsConfig.append(parts[1]);
            }
        }
    }

    if (!halfInstalled.isEmpty()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "Packages in half-installed state";
        issue.description = QString("Found %1 packages that are partially installed, indicating an interrupted update:\n%2")
            .arg(halfInstalled.size())
            .arg(halfInstalled.mid(0, 10).join(", "));
        issue.solution = "Run: sudo dpkg --configure -a && sudo apt-get install -f";
        issues.append(issue);
    }

    if (!needsConfig.isEmpty()) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "Packages need configuration";
        issue.description = QString("Found %1 packages that need to be configured:\n%2")
            .arg(needsConfig.size())
            .arg(needsConfig.mid(0, 10).join(", "));
        issue.solution = "Run: sudo dpkg --configure -a";
        issues.append(issue);
    }

    // Check if dpkg is in an inconsistent state
    QFile dpkgStatus("/var/lib/dpkg/status");
    if (dpkgStatus.exists()) {
        // Check for lock file held too long (might indicate a crashed update)
        QFile lockFile("/var/lib/dpkg/lock");
        if (lockFile.exists()) {
            QProcess fuser;
            fuser.start("fuser", QStringList() << "/var/lib/dpkg/lock");
            fuser.waitForFinished(5000);
            QString holder = fuser.readAllStandardOutput().trimmed();
            if (!holder.isEmpty()) {
                // Check how long the process has been running
                QStringList pids = holder.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
                for (const QString& pid : pids) {
                    QProcess uptime;
                    uptime.start("ps", QStringList() << "-o" << "etime=" << "-p" << pid.trimmed());
                    uptime.waitForFinished(3000);
                    QString elapsed = uptime.readAllStandardOutput().trimmed();
                    if (!elapsed.isEmpty()) {
                        // Parse elapsed time (format: [[dd-]hh:]mm:ss)
                        QStringList timeParts = elapsed.split(':');
                        int totalMinutes = 0;
                        if (timeParts.size() == 3) {
                            // hh:mm:ss or dd-hh:mm:ss
                            QString hoursPart = timeParts[0];
                            if (hoursPart.contains('-')) {
                                QStringList dayParts = hoursPart.split('-');
                                totalMinutes += dayParts[0].toInt() * 1440;
                                totalMinutes += dayParts[1].toInt() * 60;
                            } else {
                                totalMinutes += hoursPart.toInt() * 60;
                            }
                            totalMinutes += timeParts[1].toInt();
                        } else if (timeParts.size() == 2) {
                            totalMinutes = timeParts[0].toInt();
                        }

                        if (totalMinutes > 30) {
                            Issue issue;
                            issue.level = Issue::Warning;
                            issue.title = "dpkg lock held for extended time";
                            issue.description = QString("dpkg lock file has been held by PID %1 for %2 minutes, "
                                                       "which may indicate a crashed package manager")
                                .arg(pid.trimmed()).arg(totalMinutes);
                            issue.solution = "If no package operation is running, run: sudo rm /var/lib/dpkg/lock && sudo dpkg --configure -a";
                            issues.append(issue);
                        }
                    }
                }
            }
        }
    }

    return issues;
}

} // namespace DeepinDoctor
