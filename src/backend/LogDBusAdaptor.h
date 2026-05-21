#ifndef LOG_DBUS_ADAPTOR_H
#define LOG_DBUS_ADAPTOR_H

#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QStringList>

class LogDBusService;

class LogDBusAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "com.deepin.Doctor.LogService")
    Q_CLASSINFO("D-Bus Introspection", ""
        "  <interface name=\"com.deepin.Doctor.LogService\">\n"
        "    <method name=\"CheckCommand\">\n"
        "      <arg direction=\"out\" type=\"b\"/>\n"
        "    </method>\n"
        "    <method name=\"ListComponents\">\n"
        "      <arg direction=\"out\" type=\"as\"/>\n"
        "    </method>\n"
        "    <method name=\"SetDebugMode\">\n"
        "      <arg direction=\"in\" type=\"as\" name=\"components\"/>\n"
        "      <arg direction=\"in\" type=\"b\" name=\"enabled\"/>\n"
        "      <arg direction=\"out\" type=\"b\"/>\n"
        "    </method>\n"
        "    <method name=\"IsDebugEnabled\">\n"
        "      <arg direction=\"in\" type=\"s\" name=\"component\"/>\n"
        "      <arg direction=\"out\" type=\"b\"/>\n"
        "    </method>\n"
        "    <method name=\"ExportLogs\">\n"
        "      <arg direction=\"in\" type=\"as\" name=\"components\"/>\n"
        "      <arg direction=\"in\" type=\"s\" name=\"type\"/>\n"
        "      <arg direction=\"in\" type=\"s\" name=\"path\"/>\n"
        "      <arg direction=\"out\" type=\"b\"/>\n"
        "    </method>\n"
        "    <signal name=\"DebugModeChanged\">\n"
        "      <arg type=\"s\" name=\"component\"/>\n"
        "      <arg type=\"b\" name=\"enabled\"/>\n"
        "    </signal>\n"
        "    <signal name=\"ExportProgress\">\n"
        "      <arg type=\"s\" name=\"component\"/>\n"
        "      <arg type=\"d\" name=\"progress\"/>\n"
        "    </signal>\n"
        "    <signal name=\"ExportFinished\">\n"
        "      <arg type=\"b\" name=\"success\"/>\n"
        "      <arg type=\"s\" name=\"path\"/>\n"
        "    </signal>\n"
        "  </interface>\n"
    )

public:
    explicit LogDBusAdaptor(LogDBusService* parent);

public Q_SLOTS:
    bool CheckCommand();
    QStringList ListComponents();
    bool SetDebugMode(const QStringList& components, bool enabled);
    bool IsDebugEnabled(const QString& component);
    bool ExportLogs(const QStringList& components, const QString& type, const QString& path);

Q_SIGNALS:
    void DebugModeChanged(const QString& component, bool enabled);
    void ExportProgress(const QString& component, double progress);
    void ExportFinished(bool success, const QString& path);
};

#endif // LOG_DBUS_ADAPTOR_H
