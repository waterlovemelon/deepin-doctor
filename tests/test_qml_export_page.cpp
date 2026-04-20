#include <QtTest>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQmlExpression>
#include <QQmlProperty>
#include <QJSValue>
#include <QGuiApplication>
#include <QDir>

class FakeBackend : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    bool exportShouldSucceed = true;

    Q_INVOKABLE QString homePath() const
    {
        return QDir::homePath();
    }

    Q_INVOKABLE bool exportResult(const QString &, const QString &)
    {
        return exportShouldSucceed;
    }
};

class FakeTheme : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QColor surfaceColor READ surfaceColor CONSTANT)
    Q_PROPERTY(QColor elevatedSurfaceColor READ elevatedSurfaceColor CONSTANT)
    Q_PROPERTY(QColor borderColor READ borderColor CONSTANT)
    Q_PROPERTY(QColor textColor READ textColor CONSTANT)
    Q_PROPERTY(QColor mutedTextColor READ mutedTextColor CONSTANT)
    Q_PROPERTY(QColor accentColor READ accentColor CONSTANT)
    Q_PROPERTY(int radiusSm READ radiusSm CONSTANT)
    Q_PROPERTY(int radiusMd READ radiusMd CONSTANT)

public:
    QColor surfaceColor() const { return QColor("#121a2d"); }
    QColor elevatedSurfaceColor() const { return QColor("#18233b"); }
    QColor borderColor() const { return QColor("#2d3b5d"); }
    QColor textColor() const { return QColor("#f3f7ff"); }
    QColor mutedTextColor() const { return QColor("#8e9bb7"); }
    QColor accentColor() const { return QColor("#56b3ff"); }
    int radiusSm() const { return 10; }
    int radiusMd() const { return 16; }
};

class ExportPageQmlTest : public QObject
{
    Q_OBJECT

private slots:
    void loadsExportPageComponent();
    void returnsDefaultExportPath();
    void providesThemeContextForExportPage();
    void successDialogTextTracksMsgText();
    void stringifyFailureResetsExportState();
    void successfulExportDoesNotFakeProgress();
};

static QQmlComponent createExportPageComponent(QQmlEngine &engine, FakeBackend **backendOut = nullptr)
{
    static FakeTheme theme;
    const QString basePath = QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../src/frontend/qml");
    auto *backend = new FakeBackend(&engine);
    if (backendOut) {
        *backendOut = backend;
    }
    engine.rootContext()->setContextProperty("backend", backend);
    engine.rootContext()->setContextProperty("mainWindow", &theme);
    engine.addImportPath(basePath);
    return QQmlComponent(&engine, QUrl::fromLocalFile(basePath + "/pages/ExportPage.qml"));
}

static QObject *findObjectWithProperty(QObject *root, const char *propertyName)
{
    if (!root) {
        return nullptr;
    }
    if (root->property(propertyName).isValid()) {
        return root;
    }
    const auto children = root->children();
    for (QObject *child : children) {
        if (QObject *match = findObjectWithProperty(child, propertyName)) {
            return match;
        }
    }
    return nullptr;
}

void ExportPageQmlTest::loadsExportPageComponent()
{
    QQmlEngine engine;
    QQmlComponent component = createExportPageComponent(engine);

    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));
}

void ExportPageQmlTest::returnsDefaultExportPath()
{
    QQmlEngine engine;
    QQmlComponent component = createExportPageComponent(engine);
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QVariant result;
    const bool invoked = QMetaObject::invokeMethod(instance.get(), "getDefaultExportPath",
                                                   Q_RETURN_ARG(QVariant, result));
    QVERIFY(invoked);

    const QString path = result.toString();
    QVERIFY2(!path.isEmpty(), "Default export path should not be empty");
    QVERIFY2(path.endsWith(".tar.gz"), qPrintable(path));
}

void ExportPageQmlTest::providesThemeContextForExportPage()
{
    QQmlEngine engine;
    QQmlComponent component = createExportPageComponent(engine);
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QVERIFY(instance->property("isExporting").isValid());
}

void ExportPageQmlTest::successDialogTextTracksMsgText()
{
    QQmlEngine engine;
    QQmlComponent component = createExportPageComponent(engine);
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QObject *dialog = findObjectWithProperty(instance.get(), "msgText");
    QVERIFY2(dialog != nullptr, "successDialog should exist");

    dialog->setProperty("msgText", "export done");
    QCOMPARE(dialog->property("text").toString(), QString("export done"));
}

void ExportPageQmlTest::stringifyFailureResetsExportState()
{
    QQmlEngine engine;
    FakeBackend *backend = nullptr;
    QQmlComponent component = createExportPageComponent(engine, &backend);
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));
    QVERIFY(backend != nullptr);

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QQmlExpression circularValue(engine.rootContext(), instance.get(), "(function() { var x = {}; x.self = x; return x; })()",
                                 instance.get());
    const QVariant circularData = circularValue.evaluate();
    QVERIFY2(!circularValue.hasError(), qPrintable(circularValue.error().toString()));
    QVERIFY(circularData.isValid());

    QVERIFY(instance->setProperty("exportData", circularData));
    QVERIFY(!instance->property("isExporting").toBool());

    const bool ran = QMetaObject::invokeMethod(instance.get(), "startExport");
    QVERIFY(ran);
    QVERIFY2(!instance->property("isExporting").toBool(), "isExporting should reset when export serialization fails");
}

void ExportPageQmlTest::successfulExportDoesNotFakeProgress()
{
    QQmlEngine engine;
    FakeBackend *backend = nullptr;
    QQmlComponent component = createExportPageComponent(engine, &backend);
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));
    QVERIFY(backend != nullptr);

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QVERIFY(instance->setProperty("exportData", QVariantMap{{"network", "ok"}}));
    QVERIFY(instance->setProperty("exportProgress", 0.0));
    QVERIFY(!instance->property("isExporting").toBool());

    const bool ran = QMetaObject::invokeMethod(instance.get(), "startExport");
    QVERIFY(ran);

    QVERIFY2(!instance->property("isExporting").toBool(), "successful synchronous export should finish without fake progress animation");
    QCOMPARE(instance->property("exportProgress").toDouble(), 1.0);
    QTest::qWait(150);
    QCOMPARE(instance->property("exportProgress").toDouble(), 1.0);
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("deepin-doctor");
    QCoreApplication::setOrganizationName("deepin");
    QCoreApplication::setOrganizationDomain("deepin.org");
    ExportPageQmlTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "test_qml_export_page.moc"
