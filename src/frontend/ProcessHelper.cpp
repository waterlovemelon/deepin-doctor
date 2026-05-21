#include "ProcessHelper.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QTextStream>

ProcessHelper::ProcessHelper(QObject* parent) : QObject(parent) {}

QString ProcessHelper::run(const QString& program, const QStringList& arguments, int timeoutMs)
{
    emit commandStarted(program + " " + arguments.join(" "));

    QProcess proc;
    proc.start(program, arguments);

    if (!proc.waitForFinished(timeoutMs)) {
        proc.kill();
        proc.waitForFinished(1000);
        emit commandFinished(program, -1, "timeout");
        return "timeout";
    }

    QString output = QString::fromUtf8(proc.readAllStandardOutput());
    QString stderrOut = QString::fromUtf8(proc.readAllStandardError());
    if (!stderrOut.isEmpty()) {
        if (!output.isEmpty()) output += "\n";
        output += stderrOut;
    }

    emit commandFinished(program, proc.exitCode(), output);
    return output;
}

QString ProcessHelper::runFirst(const QStringList& candidates, const QStringList& arguments, int timeoutMs)
{
    for (const QString& program : candidates) {
        if (!QFile::exists(program))
            continue;

        QProcess proc;
        proc.start(program, arguments);
        if (!proc.waitForFinished(timeoutMs)) {
            proc.kill();
            proc.waitForFinished(1000);
            continue;
        }
        if (proc.exitCode() >= 0) {
            QString output = QString::fromUtf8(proc.readAllStandardOutput());
            QString stderrOut = QString::fromUtf8(proc.readAllStandardError());
            if (!stderrOut.isEmpty()) {
                if (!output.isEmpty()) output += "\n";
                output += stderrOut;
            }
            emit commandFinished(program, proc.exitCode(), output);
            return output;
        }
    }
    QString errMsg = "error: none of the candidate scripts found: " + candidates.join(", ");
    emit commandFinished("runFirst", -1, errMsg);
    return errMsg;
}

QString ProcessHelper::findTool(const QString& toolName)
{
    // Installed path
    QString installed = "/usr/lib/deepin-doctor/tools/" + toolName;
    if (QFile::exists(installed))
        return installed;

    // Build directory: binary is in build/, tools are in build/../tools/
    // Actually for this project: binary is in obj-x86_64-linux-gnu/ or build/
    // and tools would be in the same build dir's tools/ subdir after cmake
    QString appDir = QCoreApplication::applicationDirPath();
    QStringList devPaths = {
        appDir + "/tools/" + toolName,
        appDir + "/../tools/" + toolName,
        appDir + "/../src/tools/wb-keyring-helper/scripts/" + toolName,
    };
    for (const QString& path : devPaths) {
        QString canonical = QDir::cleanPath(path);
        if (QFile::exists(canonical))
            return canonical;
    }

    // Legacy path
    QString legacy = "/usr/lib/deepin/wb-keyring-helper/" + toolName;
    if (QFile::exists(legacy))
        return legacy;

    return QString();
}

QStringList ProcessHelper::availableUsers()
{
    QStringList users;
    QFile passwd("/etc/passwd");
    if (!passwd.open(QIODevice::ReadOnly | QIODevice::Text))
        return users;

    QTextStream in(&passwd);
    while (!in.atEnd()) {
        QString line = in.readLine();
        QStringList parts = line.split(':');
        if (parts.size() >= 6) {
            bool ok = false;
            uint uid = parts[2].toUInt(&ok);
            if (ok && uid >= 1000 && parts[0] != "nobody") {
                users.append(parts[0]);
            }
        }
    }
    return users;
}
