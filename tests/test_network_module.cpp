#include <QtTest>
#include <QJsonObject>
#include <QJsonArray>
#include "../src/backend/modules/network/NetworkModule.h"

class NetworkModuleTest : public QObject
{
    Q_OBJECT

private slots:
    void testCollectReturnsValidJson();
    void testDetectReturnsIssueList();
    void testDNSDetection();
    void testConnectivityDetection();
    void testModuleMetadata();
    void testProgressTracking();
    void testCancelOperation();
    void testDNSResolutionDetection();
    void testIPConflictDetection();
    void testDriverIssueDetection();
};

void NetworkModuleTest::testCollectReturnsValidJson()
{
    DeepinDoctor::NetworkModule module;
    QJsonObject result;

    module.collect(result);

    // Verify the result is a valid JSON object
    QVERIFY(!result.isEmpty());

    // Check for expected top-level keys
    QVERIFY(result.contains("status"));
    QVERIFY(result.contains("config"));
    QVERIFY(result.contains("logs"));
    QVERIFY(result.contains("services"));

    // Verify status contains expected fields
    QJsonObject status = result["status"].toObject();
    QVERIFY(status.contains("interfaces_raw"));
    QVERIFY(status.contains("routes"));

    // Verify config contains DNS info
    QJsonObject config = result["config"].toObject();
    QVERIFY(config.contains("dns_servers"));

    // Verify services contains service status
    QJsonObject services = result["services"].toObject();
    QVERIFY(services.contains("networkmanager_active"));
}

void NetworkModuleTest::testDetectReturnsIssueList()
{
    DeepinDoctor::NetworkModule module;

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

void NetworkModuleTest::testDNSDetection()
{
    DeepinDoctor::NetworkModule module;
    QJsonObject result;

    module.collect(result);

    QJsonObject config = result["config"].toObject();
    QVERIFY(config.contains("dns_servers"));

    QJsonArray dnsServers = config["dns_servers"].toArray();

    // If DNS servers are configured, they should be valid IP addresses
    for (const QJsonValue& dns : dnsServers) {
        QString dnsStr = dns.toString();
        QVERIFY(!dnsStr.isEmpty());

        // Basic IP format validation (IPv4)
        if (dnsStr.contains(".")) {
            QStringList parts = dnsStr.split(".");
            QVERIFY(parts.size() == 4);
        }
    }
}

void NetworkModuleTest::testConnectivityDetection()
{
    DeepinDoctor::NetworkModule module;

    QList<DeepinDoctor::Issue> issues = module.detect();

    // Check if connectivity issues are properly detected
    bool hasConnectivityIssue = false;
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("gateway", Qt::CaseInsensitive) ||
            issue.title.contains("connectivity", Qt::CaseInsensitive)) {
            hasConnectivityIssue = true;
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Error);
        }
    }

    // Connectivity check is environment-dependent, so we just verify it doesn't crash
    Q_UNUSED(hasConnectivityIssue);
}

void NetworkModuleTest::testModuleMetadata()
{
    DeepinDoctor::NetworkModule module;

    QCOMPARE(module.name(), QString("network"));
    QCOMPARE(module.description(), QString("Network information collector"));
    QCOMPARE(module.version(), QString("0.1.0"));

    // Default timeout should be reasonable
    QVERIFY(module.timeout() > 0);
}

void NetworkModuleTest::testProgressTracking()
{
    DeepinDoctor::NetworkModule module;

    // Initially, progress should be 0.0
    QCOMPARE(module.progress(), 0.0);

    QJsonObject result;
    module.collect(result);

    // After collection, progress should be 1.0
    QCOMPARE(module.progress(), 1.0);

    // Progress should always be between 0.0 and 1.0
    QVERIFY(module.progress() >= 0.0 && module.progress() <= 1.0);
}

void NetworkModuleTest::testCancelOperation()
{
    DeepinDoctor::NetworkModule module;

    QVERIFY(!module.isRunning());

    // Start a collect operation
    QJsonObject result;
    module.collect(result);

    // After collection completes, should not be running
    QVERIFY(!module.isRunning());

    // Cancel should set running to false
    module.cancel();
    QVERIFY(!module.isRunning());
}

void NetworkModuleTest::testDNSResolutionDetection()
{
    DeepinDoctor::NetworkModule module;

    QList<DeepinDoctor::Issue> issues = module.detect();

    // DNS resolution check is environment-dependent
    // Just verify it doesn't crash and returns valid issues
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("DNS resolution", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Error);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}

void NetworkModuleTest::testIPConflictDetection()
{
    DeepinDoctor::NetworkModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    // IP conflict check is environment-dependent, just verify no crash
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("IP conflict", Qt::CaseInsensitive)) {
            QCOMPARE(issue.level, DeepinDoctor::Issue::Error);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}

void NetworkModuleTest::testDriverIssueDetection()
{
    DeepinDoctor::NetworkModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("driver", Qt::CaseInsensitive) ||
            issue.title.contains("link down", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Info);
        }
    }
}

QTEST_MAIN(NetworkModuleTest)
#include "test_network_module.moc"
