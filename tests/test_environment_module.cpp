#include <QtTest>
#include <QJsonObject>
#include <QJsonArray>
#include "../src/backend/modules/environment/EnvironmentModule.h"

class EnvironmentModuleTest : public QObject
{
    Q_OBJECT

private slots:
    void testCollectReturnsValidJson();
    void testPackageIntegrityDetection();
    void testEnvironmentVariablesCollection();
    void testDetectReturnsIssueList();
    void testModuleMetadata();
    void testProgressTracking();
    void testCancelOperation();
    void testUpdateInterruptionDetection();
};

void EnvironmentModuleTest::testCollectReturnsValidJson()
{
    DeepinDoctor::EnvironmentModule module;
    QJsonObject result;

    module.collect(result);

    // Verify the result is a valid JSON object
    QVERIFY(!result.isEmpty());

    // Check for expected top-level keys
    QVERIFY(result.contains("packages"));
    QVERIFY(result.contains("libraries"));
    QVERIFY(result.contains("environment_variables"));
    QVERIFY(result.contains("config_files"));

    // Verify each section is an object
    QVERIFY(result["packages"].isObject());
    QVERIFY(result["libraries"].isObject());
    QVERIFY(result["environment_variables"].isObject());
    QVERIFY(result["config_files"].isObject());
}

void EnvironmentModuleTest::testPackageIntegrityDetection()
{
    DeepinDoctor::EnvironmentModule module;
    QJsonObject result;

    module.collect(result);

    QJsonObject packages = result["packages"].toObject();

    // Package integrity check should return a status
    QVERIFY(packages.contains("status"));

    QString status = packages["status"].toString();
    QVERIFY(status == "ok" || status == "warning");

    // If there are broken packages, they should be listed
    if (packages.contains("broken_packages")) {
        QJsonArray brokenPackages = packages["broken_packages"].toArray();
        QVERIFY(brokenPackages.size() >= 0);
    }

    // Lock files should be checked
    QVERIFY(packages.contains("lock_files"));
    QJsonArray lockFiles = packages["lock_files"].toArray();

    // Each lock file entry should have required fields
    for (const QJsonValue& lockValue : lockFiles) {
        QJsonObject lock = lockValue.toObject();
        QVERIFY(lock.contains("path"));
    }
}

void EnvironmentModuleTest::testEnvironmentVariablesCollection()
{
    DeepinDoctor::EnvironmentModule module;
    QJsonObject result;

    module.collect(result);

    QJsonObject envVars = result["environment_variables"].toObject();

    // Important environment variables should be collected
    QStringList expectedVars = {
        "PATH",
        "HOME",
        "USER",
        "SHELL"
    };

    for (const QString& var : expectedVars) {
        QVERIFY2(envVars.contains(var),
                 QString("Missing environment variable: %1").arg(var).toUtf8());
    }

    // PATH should not be empty
    QString path = envVars["PATH"].toString();
    QVERIFY(!path.isEmpty());

    // HOME should exist
    QString home = envVars["HOME"].toString();
    QVERIFY(!home.isEmpty());

    // USER should exist
    QString user = envVars["USER"].toString();
    QVERIFY(!user.isEmpty());

    // Check for duplicate paths if present
    if (envVars.contains("duplicate_paths")) {
        QJsonArray duplicatePaths = envVars["duplicate_paths"].toArray();
        QVERIFY(duplicatePaths.size() >= 0);
    }
}

void EnvironmentModuleTest::testDetectReturnsIssueList()
{
    DeepinDoctor::EnvironmentModule module;

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

        // Issues should have meaningful descriptions
        QVERIFY(issue.description.length() > 0);
    }
}

void EnvironmentModuleTest::testModuleMetadata()
{
    DeepinDoctor::EnvironmentModule module;

    QCOMPARE(module.name(), QString("environment"));
    QCOMPARE(module.description(), QString("System environment checker"));
    QCOMPARE(module.version(), QString("0.1.0"));

    // Default timeout should be reasonable
    QVERIFY(module.timeout() > 0);
}

void EnvironmentModuleTest::testProgressTracking()
{
    DeepinDoctor::EnvironmentModule module;

    // Initially, progress should be 0.0
    QCOMPARE(module.progress(), 0.0);

    QJsonObject result;
    module.collect(result);

    // After collection, progress should be 1.0
    QCOMPARE(module.progress(), 1.0);

    // Progress should always be between 0.0 and 1.0
    QVERIFY(module.progress() >= 0.0 && module.progress() <= 1.0);
}

void EnvironmentModuleTest::testCancelOperation()
{
    DeepinDoctor::EnvironmentModule module;

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

void EnvironmentModuleTest::testUpdateInterruptionDetection()
{
    DeepinDoctor::EnvironmentModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("half-installed", Qt::CaseInsensitive) ||
            issue.title.contains("dpkg lock", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Error ||
                    issue.level == DeepinDoctor::Issue::Warning);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}

QTEST_MAIN(EnvironmentModuleTest)
#include "test_environment_module.moc"
