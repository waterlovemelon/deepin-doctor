#include <QtTest>
#include <QJsonObject>
#include <QJsonArray>
#include "../src/backend/modules/system/SystemModule.h"

class SystemModuleTest : public QObject
{
    Q_OBJECT

private slots:
    void testCollectReturnsValidJson();
    void testHardwareInfoCollection();
    void testSystemInfoCollection();
    void testJsonFieldsExist();
    void testModuleMetadata();
    void testProgressTracking();
    void testDetectReturnsIssueList();
};

void SystemModuleTest::testCollectReturnsValidJson()
{
    DeepinDoctor::SystemModule module;
    QJsonObject result;

    module.collect(result);

    // Verify the result is a valid JSON object
    QVERIFY(!result.isEmpty());

    // Check for expected top-level keys
    QVERIFY(result.contains("hardware"));
    QVERIFY(result.contains("system"));
    QVERIFY(result.contains("logs"));

    // Verify each section is an object
    QVERIFY(result["hardware"].isObject());
    QVERIFY(result["system"].isObject());
    QVERIFY(result["logs"].isObject());
}

void SystemModuleTest::testHardwareInfoCollection()
{
    DeepinDoctor::SystemModule module;
    QJsonObject result;

    module.collect(result);

    QJsonObject hardware = result["hardware"].toObject();

    // CPU info should be present
    QVERIFY(hardware.contains("cpu_model"));
    QVERIFY(hardware.contains("cpu_cores"));

    // CPU cores should be positive
    int cpuCores = hardware["cpu_cores"].toInt();
    QVERIFY(cpuCores > 0);

    // Memory info should be present
    QVERIFY(hardware.contains("memory_total_bytes"));
    QVERIFY(hardware.contains("memory_available_bytes"));
    QVERIFY(hardware.contains("memory_used_bytes"));
    QVERIFY(hardware.contains("memory_usage_percent"));

    // Memory values should be reasonable
    qlonglong memTotal = hardware["memory_total_bytes"].toVariant().toLongLong();
    qlonglong memAvailable = hardware["memory_available_bytes"].toVariant().toLongLong();
    QVERIFY(memTotal > 0);
    QVERIFY(memAvailable >= 0);
    QVERIFY(memAvailable <= memTotal);

    // Disk info should be present
    QVERIFY(hardware.contains("disk_total"));
    QVERIFY(hardware.contains("disk_used"));
    QVERIFY(hardware.contains("disk_available"));
    QVERIFY(hardware.contains("disk_usage_percent"));

    // GPU devices should be an array
    QVERIFY(hardware.contains("gpu_devices"));
    QJsonArray gpuDevices = hardware["gpu_devices"].toArray();

    // Network devices should be an array
    QVERIFY(hardware.contains("network_devices"));
    QJsonArray netDevices = hardware["network_devices"].toArray();
}

void SystemModuleTest::testSystemInfoCollection()
{
    DeepinDoctor::SystemModule module;
    QJsonObject result;

    module.collect(result);

    QJsonObject system = result["system"].toObject();

    // OS information should be present
    QVERIFY(system.contains("os_name"));

    // Kernel information should be present
    QVERIFY(system.contains("kernel_version"));
    QVERIFY(system.contains("kernel_type"));
    QVERIFY(system.contains("architecture"));

    // Verify kernel info is not empty
    QString kernelVersion = system["kernel_version"].toString();
    QVERIFY(!kernelVersion.isEmpty());

    QString architecture = system["architecture"].toString();
    QVERIFY(!architecture.isEmpty());

    // Hostname should be present
    QVERIFY(system.contains("hostname"));
    QString hostname = system["hostname"].toString();
    QVERIFY(!hostname.isEmpty());

    // Qt version should be present
    QVERIFY(system.contains("qt_version"));

    // Uptime should be present and reasonable
    QVERIFY(system.contains("uptime_total_seconds"));
    double uptime = system["uptime_total_seconds"].toDouble();
    QVERIFY(uptime >= 0);

    // Uptime breakdown should be present
    QVERIFY(system.contains("uptime_days"));
    QVERIFY(system.contains("uptime_hours"));
    QVERIFY(system.contains("uptime_minutes"));

    int days = system["uptime_days"].toInt();
    int hours = system["uptime_hours"].toInt();
    int minutes = system["uptime_minutes"].toInt();

    QVERIFY(days >= 0);
    QVERIFY(hours >= 0 && hours < 24);
    QVERIFY(minutes >= 0 && minutes < 60);

    // Verify component versions are collected
    QVERIFY(system.contains("component_versions"));
    QJsonObject components = system["component_versions"].toObject();
    // At least glibc should be detectable on any Linux system
    QVERIFY(components.contains("glibc") || components.contains("systemd"));
}

void SystemModuleTest::testJsonFieldsExist()
{
    DeepinDoctor::SystemModule module;
    QJsonObject result;

    module.collect(result);

    // Hardware section fields
    QJsonObject hardware = result["hardware"].toObject();
    QStringList hardwareFields = {
        "cpu_model", "cpu_cores",
        "memory_total_bytes", "memory_available_bytes",
        "memory_used_bytes", "memory_usage_percent",
        "disk_total", "disk_used", "disk_available", "disk_usage_percent",
        "gpu_devices", "network_devices"
    };

    for (const QString& field : hardwareFields) {
        QVERIFY2(hardware.contains(field), QString("Missing hardware field: %1").arg(field).toUtf8());
    }

    // System section fields
    QJsonObject system = result["system"].toObject();
    QStringList systemFields = {
        "kernel_version", "kernel_type", "architecture",
        "hostname", "qt_version",
        "uptime_days", "uptime_hours", "uptime_minutes", "uptime_total_seconds"
    };

    for (const QString& field : systemFields) {
        QVERIFY2(system.contains(field), QString("Missing system field: %1").arg(field).toUtf8());
    }

    // Logs section should have at least some log data
    QJsonObject logs = result["logs"].toObject();
    QVERIFY(logs.contains("journal_system") || logs.contains("dmesg"));
}

void SystemModuleTest::testModuleMetadata()
{
    DeepinDoctor::SystemModule module;

    QCOMPARE(module.name(), QString("system"));
    QCOMPARE(module.description(), QString("System information collector"));
    QCOMPARE(module.version(), QString("0.1.0"));

    // Default timeout should be reasonable
    QVERIFY(module.timeout() > 0);
}

void SystemModuleTest::testProgressTracking()
{
    DeepinDoctor::SystemModule module;

    // Initially, progress should be 0.0
    QCOMPARE(module.progress(), 0.0);

    QJsonObject result;
    module.collect(result);

    // After collection, progress should be 1.0
    QCOMPARE(module.progress(), 1.0);

    // Progress should always be between 0.0 and 1.0
    QVERIFY(module.progress() >= 0.0 && module.progress() <= 1.0);
}

void SystemModuleTest::testDetectReturnsIssueList()
{
    DeepinDoctor::SystemModule module;

    QList<DeepinDoctor::Issue> issues = module.detect();

    // Should return a list (may be empty if no issues)
    QVERIFY(issues.size() >= 0);

    // If there are issues, verify they have required fields
    for (const DeepinDoctor::Issue& issue : issues) {
        QVERIFY(!issue.title.isEmpty());
        QVERIFY(!issue.description.isEmpty());
        QVERIFY(!issue.solution.isEmpty());
        QVERIFY(issue.level == DeepinDoctor::Issue::Error ||
                issue.level == DeepinDoctor::Issue::Warning ||
                issue.level == DeepinDoctor::Issue::Info);
    }
}

QTEST_MAIN(SystemModuleTest)
#include "test_system_module.moc"
