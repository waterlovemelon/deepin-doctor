#ifndef DBUS_ADAPTOR_H
#define DBUS_ADAPTOR_H

#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QStringList>

class DBusService;

class DBusAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "com.deepin.Doctor")
    Q_CLASSINFO("D-Bus Introspection", ""
        "  <interface name=\"com.deepin.Doctor\">\n"
        "    <method name=\"ListModules\">\n"
        "      <arg direction=\"out\" type=\"as\"/>\n"
        "    </method>\n"
        "    <method name=\"Collect\">\n"
        "      <arg direction=\"in\" type=\"as\" name=\"modules\"/>\n"
        "      <arg direction=\"out\" type=\"s\"/>\n"
        "    </method>\n"
        "    <method name=\"Detect\">\n"
        "      <arg direction=\"in\" type=\"as\" name=\"modules\"/>\n"
        "      <arg direction=\"out\" type=\"s\"/>\n"
        "    </method>\n"
        "    <method name=\"Export\">\n"
        "      <arg direction=\"in\" type=\"s\" name=\"result\"/>\n"
        "      <arg direction=\"in\" type=\"s\" name=\"outputPath\"/>\n"
        "      <arg direction=\"out\" type=\"b\"/>\n"
        "    </method>\n"
        "    <signal name=\"CollectProgress\">\n"
        "      <arg type=\"s\" name=\"taskId\"/>\n"
        "      <arg type=\"s\" name=\"module\"/>\n"
        "      <arg type=\"d\" name=\"progress\"/>\n"
        "    </signal>\n"
        "    <signal name=\"CollectFinished\">\n"
        "      <arg type=\"s\" name=\"taskId\"/>\n"
        "      <arg type=\"s\" name=\"result\"/>\n"
        "    </signal>\n"
        "  </interface>\n"
    )

public:
    explicit DBusAdaptor(DBusService* parent);

public Q_SLOTS:
    QStringList ListModules();
    QString Collect(const QStringList& modules);
    QString Detect(const QStringList& modules);
    bool Export(const QString& result, const QString& outputPath);

Q_SIGNALS:
    void CollectProgress(const QString& taskId, const QString& module, double progress);
    void CollectFinished(const QString& taskId, const QString& result);
};

#endif // DBUS_ADAPTOR_H
