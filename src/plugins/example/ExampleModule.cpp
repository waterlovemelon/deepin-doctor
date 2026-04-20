#include "ExampleModule.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QJsonArray>
#include <QTextStream>
#include <QDateTime>
#include <QSettings>

namespace DeepinDoctor {

ExampleModule::ExampleModule()
    : m_running(false)
    , m_cancelled(false)
    , m_progress(0)
{
}

ExampleModule::~ExampleModule()
{
}

QString ExampleModule::name() const
{
    return "example";
}

QString ExampleModule::description() const
{
    return "Example plugin: Collect recently opened files and application logs";
}

QString ExampleModule::version() const
{
    return "1.0.0";
}

void ExampleModule::collect(QJsonObject& result)
{
    m_running = true;
    m_cancelled = false;
    m_progress = 0;

    qDebug() << "ExampleModule: Starting collection...";

    // 收集最近打开的文件记录
    QJsonObject recentFiles;
    collectRecentlyOpenedFiles(recentFiles);

    if (m_cancelled) {
        m_running = false;
        m_progress = 0;
        return;
    }

    m_progress = 40;
    result["recent_files"] = recentFiles;

    // 收集应用访问日志
    QJsonObject appLogs;
    collectApplicationLogs(appLogs);

    if (m_cancelled) {
        m_running = false;
        m_progress = 0;
        return;
    }

    m_progress = 80;
    result["application_logs"] = appLogs;

    // 添加收集元数据
    result["collection_time"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    result["plugin_version"] = version();

    m_progress = 100;
    m_running = false;

    qDebug() << "ExampleModule: Collection completed";
}

QList<Issue> ExampleModule::detect()
{
    QList<Issue> issues;

    // 首先收集数据
    QJsonObject collectedData;
    collect(collectedData);

    if (m_cancelled) {
        return issues;
    }

    // 检查异常模式
    issues = checkForAbnormalPatterns(collectedData);

    return issues;
}

float ExampleModule::progress() const
{
    return m_progress / 100.0;
}

void ExampleModule::cancel()
{
    m_cancelled = true;
    qDebug() << "ExampleModule: Operation cancelled";
}

bool ExampleModule::isRunning() const
{
    return m_running;
}

void ExampleModule::collectRecentlyOpenedFiles(QJsonObject& result)
{
    qDebug() << "ExampleModule: Collecting recently opened files...";

    // 1. 收集GTK最近文件记录
    QString recentFile = QDir::homePath() + "/.local/share/recently-used.xbel";
    QFile gtkRecentFile(recentFile);

    QJsonArray recentItems;

    if (gtkRecentFile.exists()) {
        if (gtkRecentFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&gtkRecentFile);
            QString content = in.readAll();
            gtkRecentFile.close();

            // 简单解析：提取文件路径
            // 实际应用中应该使用XML解析器
            QStringList lines = content.split('\n');
            int count = 0;

            for (const QString& line : lines) {
                if (line.contains("href=\"file://")) {
                    int start = line.indexOf("href=\"file://") + 13;
                    int end = line.indexOf("\"", start);
                    if (start > 12 && end > start) {
                        QString filePath = line.mid(start, end - start);

                        // 检查文件是否还存在
                        QFileInfo fileInfo(filePath);
                        if (fileInfo.exists()) {
                            QJsonObject item;
                            item["path"] = filePath;
                            item["exists"] = true;
                            item["size_bytes"] = fileInfo.size();
                            item["modified_time"] = fileInfo.lastModified().toString(Qt::ISODate);
                            recentItems.append(item);

                            count++;
                            if (count >= 50) break; // 限制最多50条记录
                        }
                    }
                }

                if (m_cancelled) break;
            }

            result["gtk_recent_items"] = recentItems;
            result["gtk_recent_count"] = count;
        }
    } else {
        result["gtk_recent_items"] = QJsonArray();
        result["gtk_recent_count"] = 0;
    }

    // 2. 收集Deepin文件管理器最近文件
    QString deepinRecentFile = QDir::homePath() + "/.config/deepin/dde-file-manager/recently-used.xbel";
    QFile deepinRecent(deepinRecentFile);

    if (deepinRecent.exists()) {
        QJsonObject deepinInfo;
        deepinInfo["path"] = deepinRecentFile;
        deepinInfo["size_bytes"] = QFileInfo(deepinRecentFile).size();
        deepinInfo["last_modified"] = QFileInfo(deepinRecentFile).lastModified().toString(Qt::ISODate);
        result["deepin_recent_file_info"] = deepinInfo;
    }

    // 3. 收集特定应用的最近文件记录（示例：文本编辑器）
    QStringList appsToCheck = {
        "deepin-editor",
        "code",  // VSCode
        "sublime-text",
        "gedit"
    };

    QJsonObject appRecentFiles;

    for (const QString& app : appsToCheck) {
        QString configPath = QDir::homePath() + "/.config/" + app;
        QDir configDir(configPath);

        if (configDir.exists()) {
            QJsonObject appInfo;
            appInfo["config_path"] = configPath;

            // 查找可能的最近文件配置
            QStringList filters;
            filters << "*recent*" << "*history*" << "*session*";
            QStringList recentConfigs = configDir.entryList(filters, QDir::Files);

            QJsonArray configFiles;
            for (const QString& configFile : recentConfigs) {
                configFiles.append(configFile);
            }

            appInfo["recent_config_files"] = configFiles;
            appRecentFiles[app] = appInfo;
        }

        if (m_cancelled) break;
    }

    result["application_recent_files"] = appRecentFiles;
}

void ExampleModule::collectApplicationLogs(QJsonObject& result)
{
    qDebug() << "ExampleModule: Collecting application logs...";

    // 收集自定义应用的日志示例
    // 假设我们有一个自定义应用存储日志在 ~/.local/share/myapp/

    QString appLogDir = QDir::homePath() + "/.local/share/myapp";
    QDir logDir(appLogDir);

    if (!logDir.exists()) {
        result["status"] = "Application log directory not found";
        result["path"] = appLogDir;
        return;
    }

    // 收集日志文件列表
    QStringList logFiles = logDir.entryList(QStringList() << "*.log", QDir::Files | QDir::Readable);
    QJsonArray logFileInfos;

    for (const QString& logFileName : logFiles) {
        QString logFilePath = logDir.filePath(logFileName);
        QFile logFile(logFilePath);

        QJsonObject logInfo;
        logInfo["filename"] = logFileName;
        logInfo["size_bytes"] = QFileInfo(logFilePath).size();
        logInfo["last_modified"] = QFileInfo(logFilePath).lastModified().toString(Qt::ISODate);

        // 如果日志文件小于100KB，读取内容
        if (logFile.size() < 100 * 1024) {
            if (logFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&logFile);
                QStringList lines = in.readAll().split('\n');

                // 只保留最后100行
                QStringList lastLines = lines.mid(qMax(0, lines.size() - 100));
                logInfo["content_last_100_lines"] = lastLines.join('\n');

                logFile.close();
            }
        } else {
            logInfo["content"] = "File too large, skipped";
        }

        logFileInfos.append(logInfo);

        if (m_cancelled) break;
    }

    result["log_files"] = logFileInfos;
    result["log_file_count"] = logFiles.size();
    result["log_directory"] = appLogDir;

    // 收集应用配置文件
    QString appConfigFile = QDir::homePath() + "/.config/myapp/config.conf";
    QFile configFile(appConfigFile);

    if (configFile.exists()) {
        QJsonObject configInfo;
        configInfo["path"] = appConfigFile;
        configInfo["size_bytes"] = QFileInfo(appConfigFile).size();

        // 使用QSettings读取配置示例
        QSettings settings(appConfigFile, QSettings::IniFormat);
        QJsonObject configData;

        // 读取一些基本配置项（示例）
        QStringList keys = settings.allKeys();
        for (const QString& key : keys) {
            // 跳过敏感信息
            if (key.contains("password", Qt::CaseInsensitive) ||
                key.contains("token", Qt::CaseInsensitive) ||
                key.contains("secret", Qt::CaseInsensitive)) {
                configData[key] = "[REDACTED]";
            } else {
                configData[key] = settings.value(key).toString();
            }
        }

        configInfo["settings"] = configData;
        result["application_config"] = configInfo;
    }
}

QList<Issue> ExampleModule::checkForAbnormalPatterns(const QJsonObject& collectedData)
{
    QList<Issue> issues;

    qDebug() << "ExampleModule: Checking for abnormal patterns...";

    // 检查1：检测是否有大量最近打开文件记录异常增长
    if (collectedData.contains("recent_files")) {
        QJsonObject recentFiles = collectedData["recent_files"].toObject();

        if (recentFiles.contains("gtk_recent_count")) {
            int recentCount = recentFiles["gtk_recent_count"].toInt();

            if (recentCount > 40) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = "Large number of recent file records";
                issue.description = QString("Found %1 recent file records, which may indicate high file activity or potential privacy concern.").arg(recentCount);
                issue.solution = "Consider clearing recent file history if not needed. Use: System Settings > Privacy > Clear Recent Documents.";
                issues.append(issue);
            }
        }
    }

    // 检查2：检测是否存在已删除的最近文件引用
    // （在前面的收集阶段已经过滤了，这里可以添加其他检查）

    // 检查3：检测应用日志中的错误模式
    if (collectedData.contains("application_logs")) {
        QJsonObject appLogs = collectedData["application_logs"].toObject();

        if (appLogs.contains("log_files")) {
            QJsonArray logFiles = appLogs["log_files"].toArray();

            int errorCount = 0;
            for (const QJsonValue& logValue : logFiles) {
                QJsonObject logInfo = logValue.toObject();

                if (logInfo.contains("content_last_100_lines")) {
                    QString content = logInfo["content_last_100_lines"].toString();

                    // 统计错误关键词出现次数
                    QStringList errorKeywords = {"error", "failed", "exception", "crash"};
                    for (const QString& keyword : errorKeywords) {
                        errorCount += content.count(keyword, Qt::CaseInsensitive);
                    }
                }
            }

            if (errorCount > 10) {
                Issue issue;
                issue.level = Issue::Error;
                issue.title = "Application log shows frequent errors";
                issue.description = QString("Found %1 error-related keywords in application logs. This may indicate application instability.").arg(errorCount);
                issue.solution = "Review application logs for detailed error messages. Consider reinstalling the application or checking for system compatibility issues.";
                issues.append(issue);
            } else if (errorCount > 5) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = "Application log contains some errors";
                issue.description = QString("Found %1 error-related keywords in application logs.").arg(errorCount);
                issue.solution = "Monitor application behavior and check logs if issues persist.";
                issues.append(issue);
            }
        }
    }

    // 检查4：检测配置文件是否包含敏感信息
    if (collectedData.contains("application_logs")) {
        QJsonObject appLogs = collectedData["application_logs"].toObject();

        if (appLogs.contains("application_config")) {
            QJsonObject config = appLogs["application_config"].toObject();

            if (config.contains("settings")) {
                QJsonObject settings = config["settings"].toObject();

                // 检查是否有未加密的密码（示例检查）
                for (const QString& key : settings.keys()) {
                    QString value = settings[key].toString();

                    // 如果发现标记为[REDACTED]的值，说明存在敏感信息
                    if (value == "[REDACTED]") {
                        Issue issue;
                        issue.level = Issue::Warning;
                        issue.title = "Configuration file contains sensitive information";
                        issue.description = QString("Found potential sensitive data in configuration key: %1").arg(key);
                        issue.solution = "Ensure sensitive configuration values are properly encrypted or stored in a secure keyring.";
                        issues.append(issue);
                        break; // 只报告一次
                    }
                }
            }
        }
    }

    qDebug() << "ExampleModule: Found" << issues.size() << "issues";

    return issues;
}

} // namespace DeepinDoctor
