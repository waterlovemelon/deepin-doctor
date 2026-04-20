#include <QtTest>
#include <QSignalSpy>
#include <QJsonDocument>
#include "../src/backend/ModuleManager.h"
#include "../src/backend/modules/network/NetworkModule.h"
#include "../src/backend/modules/system/SystemModule.h"
#include "../src/backend/modules/environment/EnvironmentModule.h"

class ModuleManagerTest : public QObject
{
    Q_OBJECT

private slots:
    void testModuleRegistration();
    void testModuleList();
    void testCollectAsyncCall();
    void testDetectSyncCall();
    void testMultipleModuleRegistration();
    void testDuplicateRegistration();
    void testCollectNonExistentModule();
    void testDetectNonExistentModule();
};

void ModuleManagerTest::testModuleRegistration()
{
    ModuleManager manager;

    // Create a module
    DeepinDoctor::NetworkModule* networkModule = new DeepinDoctor::NetworkModule();

    // Register the module
    manager.registerModule(networkModule);

    // Verify the module is registered
    QStringList modules = manager.listModules();
    QVERIFY(modules.contains("network"));

    // Manager takes ownership and will delete modules in destructor
}

void ModuleManagerTest::testModuleList()
{
    ModuleManager manager;

    // Initially should have no modules
    QStringList initialModules = manager.listModules();
    QVERIFY(initialModules.isEmpty());

    // Register some modules
    DeepinDoctor::NetworkModule* networkModule = new DeepinDoctor::NetworkModule();
    DeepinDoctor::SystemModule* systemModule = new DeepinDoctor::SystemModule();

    manager.registerModule(networkModule);
    manager.registerModule(systemModule);

    // Verify both modules are in the list
    QStringList modules = manager.listModules();
    QCOMPARE(modules.size(), 2);
    QVERIFY(modules.contains("network"));
    QVERIFY(modules.contains("system"));
}

void ModuleManagerTest::testCollectAsyncCall()
{
    ModuleManager manager;

    // Register modules
    DeepinDoctor::NetworkModule* networkModule = new DeepinDoctor::NetworkModule();
    manager.registerModule(networkModule);

    // Set up signal spy
    QSignalSpy progressSpy(&manager, &ModuleManager::collectProgress);
    QSignalSpy finishedSpy(&manager, &ModuleManager::collectFinished);

    // Call collect
    QString taskId = manager.collect(QStringList{"network"});

    // TaskId should be a valid UUID
    QVERIFY(!taskId.isEmpty());
    QVERIFY(taskId.startsWith("{"));

    // Wait for async operation to complete
    QVERIFY(finishedSpy.wait(10000));

    // Verify we got a finished signal
    QCOMPARE(finishedSpy.count(), 1);

    // Verify the result
    QList<QVariant> arguments = finishedSpy.takeFirst();
    QString returnedTaskId = arguments.at(0).toString();
    QString resultJson = arguments.at(1).toString();

    QCOMPARE(returnedTaskId, taskId);

    // Parse the JSON result
    QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8());
    QVERIFY(doc.isObject());

    QJsonObject result = doc.object();
    QVERIFY(result.contains("manifest"));
    QVERIFY(result.contains("network"));
}

void ModuleManagerTest::testDetectSyncCall()
{
    ModuleManager manager;

    // Register modules
    DeepinDoctor::NetworkModule* networkModule = new DeepinDoctor::NetworkModule();
    manager.registerModule(networkModule);

    // Call detect - should be synchronous
    QList<DeepinDoctor::Issue> issues = manager.detect(QStringList{"network"});

    // Should return a valid list (may be empty)
    QVERIFY(issues.size() >= 0);

    // Verify issues have required fields
    for (const DeepinDoctor::Issue& issue : issues) {
        QVERIFY(!issue.title.isEmpty());
        QVERIFY(!issue.description.isEmpty());
        QVERIFY(!issue.solution.isEmpty());
    }
}

void ModuleManagerTest::testMultipleModuleRegistration()
{
    ModuleManager manager;

    // Register multiple modules
    DeepinDoctor::NetworkModule* networkModule = new DeepinDoctor::NetworkModule();
    DeepinDoctor::SystemModule* systemModule = new DeepinDoctor::SystemModule();
    DeepinDoctor::EnvironmentModule* envModule = new DeepinDoctor::EnvironmentModule();

    manager.registerModule(networkModule);
    manager.registerModule(systemModule);
    manager.registerModule(envModule);

    // Verify all modules are registered
    QStringList modules = manager.listModules();
    QCOMPARE(modules.size(), 3);
    QVERIFY(modules.contains("network"));
    QVERIFY(modules.contains("system"));
    QVERIFY(modules.contains("environment"));

    // Test collect on multiple modules
    QSignalSpy finishedSpy(&manager, &ModuleManager::collectFinished);
    QString taskId = manager.collect(QStringList{"network", "system", "environment"});

    QVERIFY(finishedSpy.wait(30000));

    QList<QVariant> arguments = finishedSpy.takeFirst();
    QString resultJson = arguments.at(1).toString();

    QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8());
    QJsonObject result = doc.object();

    QVERIFY(result.contains("network"));
    QVERIFY(result.contains("system"));
    QVERIFY(result.contains("environment"));
}

void ModuleManagerTest::testDuplicateRegistration()
{
    ModuleManager manager;

    // Register a module
    DeepinDoctor::NetworkModule* networkModule1 = new DeepinDoctor::NetworkModule();
    manager.registerModule(networkModule1);

    // Try to register the same module again (same name)
    DeepinDoctor::NetworkModule* networkModule2 = new DeepinDoctor::NetworkModule();
    manager.registerModule(networkModule2);

    // Should only have one module registered
    QStringList modules = manager.listModules();
    QCOMPARE(modules.size(), 1);

    // Second module should not be registered, so we need to delete it
    delete networkModule2;
}

void ModuleManagerTest::testCollectNonExistentModule()
{
    ModuleManager manager;

    // Register no modules
    QSignalSpy finishedSpy(&manager, &ModuleManager::collectFinished);

    // Try to collect from non-existent module
    QString taskId = manager.collect(QStringList{"nonexistent"});

    // Should still complete (with empty result)
    QVERIFY(finishedSpy.wait(5000));

    QList<QVariant> arguments = finishedSpy.takeFirst();
    QString resultJson = arguments.at(1).toString();

    QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8());
    QJsonObject result = doc.object();

    // Should have manifest but not the non-existent module
    QVERIFY(result.contains("manifest"));
    QVERIFY(!result.contains("nonexistent"));
}

void ModuleManagerTest::testDetectNonExistentModule()
{
    ModuleManager manager;

    // Try to detect from non-existent module
    QList<DeepinDoctor::Issue> issues = manager.detect(QStringList{"nonexistent"});

    // Should return empty list without crashing
    QVERIFY(issues.isEmpty());
}

QTEST_MAIN(ModuleManagerTest)
#include "test_module_manager.moc"
