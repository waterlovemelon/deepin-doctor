#include "SystemModule.h"
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QJsonArray>
#include <QTextStream>
#include <QSysInfo>

namespace DeepinDoctor {

SystemModule::SystemModule()
{
}

SystemModule::~SystemModule()
{
}

void SystemModule::collect(QJsonObject& result)
{
    m_running = true;
    m_progress = 0.0;

    QJsonObject hardware, system, logs;

    collectHardwareInfo(hardware);
    m_progress = 0.33;
    result["hardware"] = hardware;

    collectSystemInfo(system);
    m_progress = 0.66;
    result["system"] = system;

    collectSystemLogs(logs);
    m_progress = 1.0;
    result["logs"] = logs;

    m_running = false;
}

QList<Issue> SystemModule::detect()
{
    QList<Issue> issues;

    // TODO: Add disk space checks, memory checks, etc.

    return issues;
}

void SystemModule::cancel()
{
    m_running = false;
}

void SystemModule::collectHardwareInfo(QJsonObject& result)
{
    // CPU info
    QFile cpuInfo("/proc/cpuinfo");
    if (cpuInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuInfo);
        QString content = in.readAll();
        cpuInfo.close();

        QStringList lines = content.split('\n');
        QString modelName;
        int cpuCores = 0;

        for (const QString& line : lines) {
            if (line.startsWith("model name")) {
                modelName = line.split(':').last().trimmed();
            }
            if (line.startsWith("processor")) {
                cpuCores++;
            }
        }

        result["cpu_model"] = modelName;
        result["cpu_cores"] = cpuCores;
    }

    // CPU usage from /proc/stat
    QFile cpuStat("/proc/stat");
    if (cpuStat.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream cpuIn(&cpuStat);
        QString cpuLine = cpuIn.readLine(); // First line: cpu  user nice system idle ...
        cpuStat.close();

        QStringList cpuParts = cpuLine.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
        if (cpuParts.size() >= 5) {
            // cpuParts[0] = "cpu", [1]=user, [2]=nice, [3]=system, [4]=idle
            qlonglong user = cpuParts[1].toLongLong();
            qlonglong nice = cpuParts[2].toLongLong();
            qlonglong system = cpuParts[3].toLongLong();
            qlonglong idle = cpuParts[4].toLongLong();
            qlonglong total = user + nice + system + idle;

            result["cpu_user_jiffies"] = user;
            result["cpu_system_jiffies"] = system;
            result["cpu_idle_jiffies"] = idle;
            result["cpu_total_jiffies"] = total;

            // Usage percentage (snapshot, not over time)
            if (total > 0) {
                double usage = (total - idle) * 100.0 / total;
                result["cpu_usage_percent"] = usage;
            }
        }
    }

    // Memory info
    QFile memInfo("/proc/meminfo");
    if (memInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&memInfo);
        QString content = in.readAll();
        memInfo.close();

        QStringList lines = content.split('\n');
        qlonglong memTotal = 0, memAvailable = 0;

        for (const QString& line : lines) {
            if (line.startsWith("MemTotal:")) {
                memTotal = line.split(QRegExp("\\s+"))[1].toLongLong() * 1024;
            }
            if (line.startsWith("MemAvailable:")) {
                memAvailable = line.split(QRegExp("\\s+"))[1].toLongLong() * 1024;
            }
        }

        result["memory_total_bytes"] = memTotal;
        result["memory_available_bytes"] = memAvailable;
        result["memory_used_bytes"] = memTotal - memAvailable;
        result["memory_usage_percent"] = (memTotal - memAvailable) * 100.0 / memTotal;
    }

    // Disk info
    QProcess process;
    process.start("df", QStringList() << "-h" << "/");
    process.waitForFinished(5000);
    QString dfOutput = process.readAllStandardOutput();

    QStringList dfLines = dfOutput.split('\n');
    if (dfLines.size() >= 2) {
        QStringList parts = dfLines[1].split(QRegExp("\\s+"));
        if (parts.size() >= 5) {
            result["disk_total"] = parts[1];
            result["disk_used"] = parts[2];
            result["disk_available"] = parts[3];
            result["disk_usage_percent"] = parts[4].replace('%', "");
        }
    }

    // Disk IO stats from /proc/diskstats
    QFile diskStats("/proc/diskstats");
    if (diskStats.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream dsIn(&diskStats);
        QString dsContent = dsIn.readAll();
        diskStats.close();

        // Parse for the root device (sda or vda)
        QStringList dsLines = dsContent.split('\n');
        for (const QString& line : dsLines) {
            if (line.contains(" sda ") || line.contains(" vda ") ||
                line.contains(" nvme0n1 ")) {
                QStringList parts = line.trimmed().split(QRegExp("\\s+"));
                if (parts.size() >= 14) {
                    QJsonObject ioInfo;
                    ioInfo["reads_completed"] = parts[3].toLongLong();
                    ioInfo["sectors_read"] = parts[5].toLongLong();
                    ioInfo["writes_completed"] = parts[7].toLongLong();
                    ioInfo["sectors_written"] = parts[9].toLongLong();
                    result["disk_io"] = ioInfo;
                }
                break;
            }
        }
    }

    // Graphics info
    process.start("lspci", QStringList());
    process.waitForFinished(5000);
    QString lspciOutput = process.readAllStandardOutput();

    QStringList gpuDevices;
    QStringList lspciLines = lspciOutput.split('\n');
    for (const QString& line : lspciLines) {
        if (line.contains("VGA", Qt::CaseInsensitive) ||
            line.contains("3D", Qt::CaseInsensitive) ||
            line.contains("Display", Qt::CaseInsensitive)) {
            gpuDevices.append(line);
        }
    }
    result["gpu_devices"] = QJsonArray::fromStringList(gpuDevices);

    // Network devices
    process.start("lspci", QStringList());
    process.waitForFinished(5000);
    QString lspciAgain = process.readAllStandardOutput();

    QStringList netDevices;
    QStringList lspciAgainLines = lspciAgain.split('\n');
    for (const QString& line : lspciAgainLines) {
        if (line.contains("Ethernet", Qt::CaseInsensitive) ||
            line.contains("Network", Qt::CaseInsensitive)) {
            netDevices.append(line);
        }
    }
    result["network_devices"] = QJsonArray::fromStringList(netDevices);
}

void SystemModule::collectSystemInfo(QJsonObject& result)
{
    // System version
    QFile osRelease("/etc/os-release");
    if (osRelease.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&osRelease);
        QString content = in.readAll();
        osRelease.close();

        QStringList lines = content.split('\n');
        for (const QString& line : lines) {
            if (line.startsWith("PRETTY_NAME=")) {
                result["os_name"] = line.split('=').last().remove('"');
            }
            if (line.startsWith("VERSION=")) {
                result["os_version"] = line.split('=').last().remove('"');
            }
        }
    }

    // LSB release
    QFile lsbRelease("/etc/lsb-release");
    if (lsbRelease.exists()) {
        if (lsbRelease.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&lsbRelease);
            QString content = in.readAll();
            lsbRelease.close();

            QStringList lines = content.split('\n');
            for (const QString& line : lines) {
                if (line.startsWith("DISTRIB_DESCRIPTION=")) {
                    result["lsb_description"] = line.split('=').last().remove('"');
                }
            }
        }
    }

    // Kernel version
    result["kernel_version"] = QSysInfo::kernelVersion();
    result["kernel_type"] = QSysInfo::kernelType();
    result["architecture"] = QSysInfo::currentCpuArchitecture();

    // Hostname
    result["hostname"] = QSysInfo::machineHostName();

    // Qt version
    result["qt_version"] = qVersion();

    // Boot time
    QFile uptime("/proc/uptime");
    if (uptime.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&uptime);
        QString content = in.readAll();
        uptime.close();

        double uptimeSeconds = content.split(' ').first().toDouble();
        int days = uptimeSeconds / 86400;
        int hours = (uptimeSeconds - days * 86400) / 3600;
        int minutes = (uptimeSeconds - days * 86400 - hours * 3600) / 60;

        result["uptime_days"] = days;
        result["uptime_hours"] = hours;
        result["uptime_minutes"] = minutes;
        result["uptime_total_seconds"] = uptimeSeconds;
    }

    // Desktop environment
    QProcess process;
    process.start("ps", QStringList() << "-e");
    process.waitForFinished(5000);
    QString psOutput = process.readAllStandardOutput();

    QString desktopEnv;
    if (psOutput.contains("dde-desktop") || psOutput.contains("dde-dock")) {
        desktopEnv = "DDE (Deepin Desktop Environment)";
    } else if (psOutput.contains("gnome-shell")) {
        desktopEnv = "GNOME";
    } else if (psOutput.contains("plasmashell")) {
        desktopEnv = "KDE Plasma";
    }

    result["desktop_environment"] = desktopEnv;

    // Key packages version
    QStringList keyPackages = {"qtbase5-dev", "glibc", "systemd", "dde-desktop"};
    QJsonObject packageVersions;

    for (const QString& pkg : keyPackages) {
        process.start("dpkg", QStringList() << "-s" << pkg);
        process.waitForFinished(5000);
        QString pkgInfo = process.readAllStandardOutput();

        QStringList infoLines = pkgInfo.split('\n');
        for (const QString& infoLine : infoLines) {
            if (infoLine.startsWith("Version:")) {
                packageVersions[pkg] = infoLine.split(':').last().trimmed();
                break;
            }
        }
    }

    result["package_versions"] = packageVersions;

    // Collect key component versions
    QJsonObject componentVersions;

    // glibc version
    process.start("ldd", QStringList() << "--version");
    process.waitForFinished(5000);
    QString lddOutput = process.readAllStandardOutput();
    if (!lddOutput.isEmpty()) {
        QStringList lddLines = lddOutput.split('\n');
        if (!lddLines.isEmpty()) {
            componentVersions["glibc"] = lddLines.first().trimmed();
        }
    }

    // systemd version
    process.start("systemctl", QStringList() << "--version");
    process.waitForFinished(5000);
    QString systemdOutput = process.readAllStandardOutput();
    if (!systemdOutput.isEmpty()) {
        QStringList systemdLines = systemdOutput.split('\n');
        if (!systemdLines.isEmpty()) {
            componentVersions["systemd"] = systemdLines.first().trimmed();
        }
    }

    // GCC version
    process.start("gcc", QStringList() << "--version");
    process.waitForFinished(5000);
    QString gccOutput = process.readAllStandardOutput();
    if (!gccOutput.isEmpty()) {
        QStringList gccLines = gccOutput.split('\n');
        if (!gccLines.isEmpty()) {
            componentVersions["gcc"] = gccLines.first().trimmed();
        }
    }

    // Xorg version
    process.start("Xorg", QStringList() << "-version");
    process.waitForFinished(5000);
    QString xorgOutput = process.readAllStandardError(); // Xorg prints version to stderr
    if (!xorgOutput.isEmpty()) {
        QStringList xorgLines = xorgOutput.split('\n');
        for (const QString& line : xorgLines) {
            if (line.contains("X.Org")) {
                componentVersions["xorg"] = line.trimmed();
                break;
            }
        }
    }

    result["component_versions"] = componentVersions;
}

void SystemModule::collectSystemLogs(QJsonObject& result)
{
    QProcess process;

    // System journal (last 500 lines)
    process.start("journalctl", QStringList() << "-n" << "500" << "--no-pager");
    process.waitForFinished(10000);
    QString journalLog = process.readAllStandardOutput();
    result["journal_system"] = journalLog;

    // Kernel log
    process.start("dmesg", QStringList());
    process.waitForFinished(5000);
    QString dmesgLog = process.readAllStandardOutput();
    result["dmesg"] = dmesgLog;

    // X11 log (if exists)
    QFile xorgLog("/var/log/Xorg.0.log");
    if (xorgLog.exists()) {
        if (xorgLog.size() < 1024 * 1024) { // Only if < 1MB
            if (xorgLog.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&xorgLog);
                result["xorg_log"] = in.readAll();
                xorgLog.close();
            }
        } else {
            result["xorg_log"] = "File too large (>1MB), skipped";
        }
    }

    // syslog (if exists)
    QFile syslogFile("/var/log/syslog");
    if (syslogFile.exists()) {
        if (syslogFile.size() < 2 * 1024 * 1024) { // Only if < 2MB
            if (syslogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&syslogFile);
                QStringList allLines = in.readAll().split('\n');
                syslogFile.close();
                // Last 500 lines
                QStringList lastLines = allLines.mid(qMax(0, allLines.size() - 500));
                result["syslog"] = lastLines.join('\n');
            }
        } else {
            // Read last 500 lines efficiently
            if (syslogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&syslogFile);
                in.seek(qMax(0LL, syslogFile.size() - 100 * 1024)); // Read last 100KB
                result["syslog"] = in.readAll();
                syslogFile.close();
            }
        }
    }

    // kern.log (if exists)
    QFile kernlogFile("/var/log/kern.log");
    if (kernlogFile.exists()) {
        if (kernlogFile.size() < 2 * 1024 * 1024) {
            if (kernlogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&kernlogFile);
                QStringList allLines = in.readAll().split('\n');
                kernlogFile.close();
                QStringList lastLines = allLines.mid(qMax(0, allLines.size() - 500));
                result["kern_log"] = lastLines.join('\n');
            }
        }
    }

    // Wayland compositor log
    QString waylandLogDir = QDir::homePath() + "/.local/share/wayland";
    QDir waylandDir(waylandLogDir);
    if (waylandDir.exists()) {
        QStringList waylandLogs = waylandDir.entryList(QStringList() << "*.log", QDir::Files);
        QJsonObject waylandLogData;
        for (const QString& logFile : waylandLogs) {
            QFile file(waylandDir.filePath(logFile));
            if (file.size() < 512 * 1024) {
                if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QTextStream in(&file);
                    waylandLogData[logFile] = in.readAll();
                    file.close();
                }
            }
        }
        if (!waylandLogData.isEmpty()) {
            result["wayland_logs"] = waylandLogData;
        }
    }

    // Check XDG_SESSION_TYPE to note if running Wayland
    QString sessionType = qEnvironmentVariable("XDG_SESSION_TYPE");
    if (!sessionType.isEmpty()) {
        result["session_type"] = sessionType;
    }

    // DDE logs
    QDir ddeLogDir(QDir::homePath() + "/.cache/deepin");
    if (ddeLogDir.exists()) {
        QStringList logFiles = ddeLogDir.entryList(QStringList() << "*.log", QDir::Files);
        QJsonObject ddeLogs;

        for (const QString& logFile : logFiles) {
            QString filePath = ddeLogDir.filePath(logFile);
            QFile file(filePath);

            if (file.size() < 512 * 1024) { // Only if < 512KB
                if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QTextStream in(&file);
                    // Read last 200 lines
                    QStringList lines = in.readAll().split('\n');
                    QStringList lastLines = lines.mid(qMax(0, lines.size() - 200));
                    ddeLogs[logFile] = lastLines.join('\n');
                    file.close();
                }
            }
        }

        result["dde_logs"] = ddeLogs;
    }
}

} // namespace DeepinDoctor
