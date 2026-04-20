#include "LogsModule.h"
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QJsonArray>
#include <QTextStream>
#include <QStandardPaths>

namespace DeepinDoctor {

LogsModule::LogsModule()
{
}

LogsModule::~LogsModule()
{
}

void LogsModule::collect(QJsonObject& result)
{
    m_running = true;
    m_progress = 0.0;

    QJsonObject appLogs, serviceLogs, crashReports;

    collectApplicationLogs(appLogs);
    m_progress = 0.33;
    result["application_logs"] = appLogs;

    collectServiceLogs(serviceLogs);
    m_progress = 0.66;
    result["service_logs"] = serviceLogs;

    collectCrashReports(crashReports);
    m_progress = 1.0;
    result["crash_reports"] = crashReports;

    m_running = false;
}

QList<Issue> LogsModule::detect()
{
    QList<Issue> issues;

    // Check for recent crashes
    QString crashDir = "/var/crash";
    QDir dir(crashDir);
    if (dir.exists()) {
        QStringList crashes = dir.entryList(QStringList() << "*.crash", QDir::Files);
        if (crashes.size() > 5) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Multiple crash reports detected";
            issue.description = QString("Found %1 crash reports in %2").arg(crashes.size()).arg(crashDir);
            issue.solution = "Review crash reports and fix underlying issues";
            issues.append(issue);
        }
    }

    return issues;
}

void LogsModule::cancel()
{
    m_running = false;
}

void LogsModule::collectApplicationLogs(QJsonObject& result)
{
    // DDE application logs
    QStringList ddeApps = {
        "dde-desktop",
        "dde-dock",
        "dde-launcher",
        "dde-control-center",
        "dde-file-manager",
        "dde-polkit-agent"
    };

    QProcess process;
    for (const QString& app : ddeApps) {
        process.start("journalctl", QStringList() << "-u" << app << "-n" << "200" << "--no-pager");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[app] = logs;
        }
    }

    // Deepin application logs in ~/.cache/deepin
    QString deepinCacheDir = QDir::homePath() + "/.cache/deepin";
    QDir cacheDir(deepinCacheDir);

    if (cacheDir.exists()) {
        QStringList logFiles = findLogFiles(deepinCacheDir, "*.log");
        QJsonObject deepinLogs;

        for (const QString& logFile : logFiles) {
            QString content = readLogFile(logFile, 300);
            if (!content.isEmpty()) {
                QFileInfo info(logFile);
                deepinLogs[info.fileName()] = content;
            }
        }

        result["deepin_cache_logs"] = deepinLogs;
    }

    // User application logs in ~/.local/share
    QString localShareDir = QDir::homePath() + "/.local/share";
    QDir localDir(localShareDir);

    if (localDir.exists()) {
        QStringList appDirs = localDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        QJsonObject userAppLogs;

        for (const QString& appDir : appDirs) {
            QString appPath = localDir.filePath(appDir);
            QStringList logFiles = findLogFiles(appPath, "*.log");

            if (!logFiles.isEmpty()) {
                QJsonObject appLogs;
                for (const QString& logFile : logFiles) {
                    QString content = readLogFile(logFile, 200);
                    if (!content.isEmpty()) {
                        QFileInfo info(logFile);
                        appLogs[info.fileName()] = content;
                    }
                }
                userAppLogs[appDir] = appLogs;
            }
        }

        result["user_app_logs"] = userAppLogs;
    }
}

void LogsModule::collectServiceLogs(QJsonObject& result)
{
    QProcess process;

    // System services logs
    QStringList services = {
        "systemd",
        "dbus",
        "systemd-logind",
        "systemd-resolved",
        "NetworkManager",
        "wpa_supplicant",
        "lightdm",
        "sshd"
    };

    for (const QString& service : services) {
        process.start("journalctl", QStringList() << "-u" << service << "-n" << "100" << "--no-pager");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[service] = logs;
        }
    }

    // Deepin services
    QStringList deepinServices = {
        "deepin-anything-monitor",
        "dde-session-daemon",
        "dde-system-daemon"
    };

    for (const QString& service : deepinServices) {
        process.start("journalctl", QStringList() << "-u" << service << "-n" << "100" << "--no-pager");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[service] = logs;
        }
    }
}

void LogsModule::collectCrashReports(QJsonObject& result)
{
    // System crash reports
    QString crashDir = "/var/crash";
    QDir dir(crashDir);

    if (dir.exists()) {
        QStringList crashFiles = dir.entryList(QStringList() << "*.crash", QDir::Files);
        QJsonArray crashes;

        for (const QString& crashFile : crashFiles) {
            QString filePath = dir.filePath(crashFile);
            QFileInfo info(filePath);

            QJsonObject crashInfo;
            crashInfo["filename"] = crashFile;
            crashInfo["size"] = (qint64)info.size();
            crashInfo["modified"] = info.lastModified().toString(Qt::ISODate);

            // Try to extract crash time and application from filename
            // Format usually: <app>_<version>_<timestamp>.crash
            QStringList parts = crashFile.split('_');
            if (parts.size() >= 1) {
                crashInfo["application"] = parts[0];
            }

            crashes.append(crashInfo);
        }

        result["system_crashes"] = crashes;
    }

    // Core dumps (if enabled)
    QProcess process;
    process.start("coredumpctl", QStringList() << "list" << "-n" << "20");
    process.waitForFinished(5000);
    QString coredumpList = process.readAllStandardOutput();

    if (!coredumpList.isEmpty()) {
        result["coredump_list"] = coredumpList;
    }

    // User crash reports in ~/.local/share/sentry
    QString sentryDir = QDir::homePath() + "/.local/share/sentry";
    QDir sentryD(sentryDir);

    if (sentryD.exists()) {
        QStringList reports = sentryD.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        result["sentry_reports"] = QJsonArray::fromStringList(reports);
    }
}

QString LogsModule::readLogFile(const QString& path, int maxLines)
{
    QFile file(path);

    if (!file.exists() || file.size() > 5 * 1024 * 1024) { // Skip if > 5MB
        return QString("File too large or not accessible: %1 bytes").arg(file.size());
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }

    QTextStream in(&file);
    QStringList allLines = in.readAll().split('\n');
    file.close();

    // Return last maxLines
    QStringList lastLines = allLines.mid(qMax(0, allLines.size() - maxLines));
    return lastLines.join('\n');
}

QStringList LogsModule::findLogFiles(const QString& dir, const QString& pattern)
{
    QStringList result;
    QDir directory(dir);

    if (!directory.exists()) {
        return result;
    }

    QDirIterator it(dir, QStringList() << pattern, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        result.append(it.next());
    }

    return result;
}

} // namespace DeepinDoctor
