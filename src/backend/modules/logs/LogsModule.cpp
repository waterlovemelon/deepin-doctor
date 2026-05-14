#include "LogsModule.h"
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QJsonArray>
#include <QTextStream>
#include <QStandardPaths>
#include <QDateTime>
#include <QRegularExpression>

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
        // Use --since to limit log range (last 24 hours by default)
        process.start("journalctl", QStringList() << "-u" << app << "-n" << "200" << "--no-pager" << "--since" << "24 hours ago");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[app] = maskSensitiveInfo(logs);
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
                deepinLogs[info.fileName()] = maskSensitiveInfo(content);
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
                        appLogs[info.fileName()] = maskSensitiveInfo(content);
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
        // Use --since to limit log range (last 24 hours by default)
        process.start("journalctl", QStringList() << "-u" << service << "-n" << "100" << "--no-pager" << "--since" << "24 hours ago");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[service] = maskSensitiveInfo(logs);
        }
    }

    // Deepin services
    QStringList deepinServices = {
        "deepin-anything-monitor",
        "dde-session-daemon",
        "dde-system-daemon"
    };

    for (const QString& service : deepinServices) {
        // Use --since to limit log range (last 24 hours by default)
        process.start("journalctl", QStringList() << "-u" << service << "-n" << "100" << "--no-pager" << "--since" << "24 hours ago");
        process.waitForFinished(10000);
        QString logs = process.readAllStandardOutput();

        if (!logs.isEmpty()) {
            result[service] = maskSensitiveInfo(logs);
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
        result["coredump_list"] = maskSensitiveInfo(coredumpList);
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

QString LogsModule::filterByTimeRange(const QString& logContent, int hoursBack)
{
    QDateTime cutoff = QDateTime::currentDateTime().addSecs(-hoursBack * 3600);
    QStringList filteredLines;

    QStringList lines = logContent.split('\n');
    for (const QString& line : lines) {
        // Try to parse the timestamp from common log formats
        bool keep = true;

        // Try ISO format (2026-05-14T10:30:00)
        QRegularExpression isoRe("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})");
        QRegularExpressionMatch isoMatch = isoRe.match(line);
        if (isoMatch.hasMatch()) {
            QDateTime logTime = QDateTime::fromString(isoMatch.captured(1), Qt::ISODate);
            if (logTime.isValid() && logTime < cutoff) {
                keep = false;
            }
        }

        // Try syslog format (May 14 10:30:00)
        QRegularExpression syslogRe("(\\w{3})\\s+(\\d{1,2})\\s+(\\d{2}:\\d{2}:\\d{2})");
        QRegularExpressionMatch syslogMatch = syslogRe.match(line);
        if (syslogMatch.hasMatch() && !isoMatch.hasMatch()) {
            QString month = syslogMatch.captured(1);
            int day = syslogMatch.captured(2).toInt();
            QString time = syslogMatch.captured(3);

            // Build date string for current year
            QDate logDate = QDate::currentDate();
            int monthNum = QDate::fromString(month, "MMM").month();
            if (monthNum > 0) {
                logDate = QDate(QDate::currentDate().year(), monthNum, day);
            }

            QDateTime logTime = QDateTime::fromString(
                logDate.toString("yyyy-MM-dd") + " " + time, "yyyy-MM-dd HH:mm:ss");
            if (logTime.isValid() && logTime < cutoff) {
                keep = false;
            }
        }

        if (keep) {
            filteredLines.append(line);
        }
    }

    return filteredLines.join('\n');
}

QString LogsModule::maskSensitiveInfo(const QString& content)
{
    QString masked = content;

    // Mask password-like patterns (password=xxx, passwd=xxx, pwd=xxx)
    masked.replace(QRegularExpression("(password|passwd|pwd|secret|token|api_key|apikey)\\s*[=:]\\s*\\S+",
                   QRegularExpression::CaseInsensitiveOption),
                   "\\1=***REDACTED***");

    // Mask connection strings with passwords (e.g., postgresql://user:pass@host)
    masked.replace(QRegularExpression("(://[^:]+:)[^@]+(@)"),
                   "\\1***REDACTED***\\2");

    // Mask SSH private key content
    masked.replace(QRegularExpression("-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----[\\s\\S]*?-----END (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"),
                   "-----BEGIN PRIVATE KEY-----\n***REDACTED***\n-----END PRIVATE KEY-----");

    // Mask environment variables with sensitive names
    masked.replace(QRegularExpression("((?:export\\s+)?(?:DB_PASSWORD|DATABASE_PASSWORD|MYSQL_PWD|PGPASSWORD|AWS_SECRET_ACCESS_KEY|SECRET_KEY)=)\\S+",
                   QRegularExpression::CaseInsensitiveOption),
                   "\\1***REDACTED***");

    return masked;
}

} // namespace DeepinDoctor
