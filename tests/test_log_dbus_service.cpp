#include <QtTest>
#include <QStringList>
#include "../src/backend/LogDBusService.h"

class LogDBusServiceTest : public QObject
{
    Q_OBJECT

private slots:
    void testListComponentsReturnsNonEmpty();
    void testListComponentsContainsExpectedEntries();
    void testSetDebugModeWithEmptyList();
    void testExportLogsReturnsTrue();
};

void LogDBusServiceTest::testListComponentsReturnsNonEmpty()
{
    LogDBusService service;
    QStringList components = service.ListComponents();
    QVERIFY(!components.isEmpty());
}

void LogDBusServiceTest::testListComponentsContainsExpectedEntries()
{
    LogDBusService service;
    QStringList components = service.ListComponents();
    QVERIFY(components.contains("dde-desktop"));
    QVERIFY(components.contains("dde-dock"));
    QVERIFY(components.contains("dde-file-manager"));
}

void LogDBusServiceTest::testSetDebugModeWithEmptyList()
{
    LogDBusService service;
    bool result = service.SetDebugMode({}, true);
    QVERIFY(result);
}

void LogDBusServiceTest::testExportLogsReturnsTrue()
{
    LogDBusService service;
    bool result = service.ExportLogs({"dde-dock"}, "collected", "/tmp/test.tar.gz");
    QVERIFY(result);
}

QTEST_MAIN(LogDBusServiceTest)
#include "test_log_dbus_service.moc"
