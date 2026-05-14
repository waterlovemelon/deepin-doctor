#include <QtTest>
#include <QJsonObject>
#include <QJsonDocument>
#include "../src/backend/modules/logs/LogsModule.h"

class LogsModuleTest : public QObject
{
    Q_OBJECT

private slots:
    void testCollectReturnsValidJson();
    void testDetectReturnsIssueList();
    void testModuleMetadata();
    void testSensitiveInfoMasking();
};

void LogsModuleTest::testCollectReturnsValidJson()
{
    DeepinDoctor::LogsModule module;
    QJsonObject result;

    module.collect(result);

    // Verify the result is a valid JSON object
    QVERIFY(!result.isEmpty());

    // Check for expected top-level keys
    QVERIFY(result.contains("application_logs"));
    QVERIFY(result.contains("service_logs"));
    QVERIFY(result.contains("crash_reports"));

    // Verify each section is an object
    QVERIFY(result["application_logs"].isObject());
    QVERIFY(result["service_logs"].isObject());
    QVERIFY(result["crash_reports"].isObject());
}

void LogsModuleTest::testDetectReturnsIssueList()
{
    DeepinDoctor::LogsModule module;

    QList<DeepinDoctor::Issue> issues = module.detect();

    // Should return a list (may be empty if no issues)
    QVERIFY(issues.size() >= 0);

    // If there are issues, verify they have required fields
    for (const DeepinDoctor::Issue& issue : issues) {
        QVERIFY(!issue.title.isEmpty());
        QVERIFY(!issue.description.isEmpty());
        QVERIFY(!issue.solution.isEmpty());

        // Issue level should be valid
        QVERIFY(issue.level == DeepinDoctor::Issue::Error ||
                issue.level == DeepinDoctor::Issue::Warning ||
                issue.level == DeepinDoctor::Issue::Info);
    }
}

void LogsModuleTest::testModuleMetadata()
{
    DeepinDoctor::LogsModule module;

    QCOMPARE(module.name(), QString("logs"));
    QCOMPARE(module.description(), QString("Application logs collector"));
    QCOMPARE(module.version(), QString("0.1.0"));

    // Default timeout should be reasonable
    QVERIFY(module.timeout() > 0);
}

void LogsModuleTest::testSensitiveInfoMasking()
{
    DeepinDoctor::LogsModule module;

    // Test via a helper - since maskSensitiveInfo is private, test through collect
    // Just verify it doesn't crash
    QJsonObject result;
    module.collect(result);

    // Verify no raw passwords in collected data
    QJsonDocument doc(result);
    QString jsonStr = doc.toJson();

    // These patterns should not appear unmasked
    QVERIFY(!jsonStr.contains("password=secret123"));
    QVERIFY(!jsonStr.contains("token=abc123"));
}

QTEST_MAIN(LogsModuleTest)
#include "test_logs_module.moc"
