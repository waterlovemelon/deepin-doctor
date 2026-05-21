#pragma once

#include <QObject>
#include <QProcess>
#include <QQmlEngine>

class ProcessHelper : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit ProcessHelper(QObject* parent = nullptr);

    Q_INVOKABLE QString run(const QString& program, const QStringList& arguments = {}, int timeoutMs = 30000);
    Q_INVOKABLE QString runFirst(const QStringList& candidates, const QStringList& arguments = {}, int timeoutMs = 30000);
    Q_INVOKABLE QString findTool(const QString& toolName);
    Q_INVOKABLE QStringList availableUsers();

signals:
    void commandStarted(const QString& command);
    void commandFinished(const QString& command, int exitCode, const QString& output);
};
