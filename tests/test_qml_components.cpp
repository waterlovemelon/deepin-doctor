#include <QtTest>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QQuickItem>
#include <QColor>
#include <QDir>
#include <QSignalSpy>

class FakeTheme : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QColor surfaceColor READ surfaceColor CONSTANT)
    Q_PROPERTY(QColor elevatedSurfaceColor READ elevatedSurfaceColor CONSTANT)
    Q_PROPERTY(QColor borderColor READ borderColor CONSTANT)
    Q_PROPERTY(QColor textColor READ textColor CONSTANT)
    Q_PROPERTY(QColor mutedTextColor READ mutedTextColor CONSTANT)
    Q_PROPERTY(QColor accentColor READ accentColor CONSTANT)
    Q_PROPERTY(QColor successColor READ successColor CONSTANT)
    Q_PROPERTY(QColor warningColor READ warningColor CONSTANT)
    Q_PROPERTY(QColor errorColor READ errorColor CONSTANT)
    Q_PROPERTY(int radiusSm READ radiusSm CONSTANT)
    Q_PROPERTY(int radiusMd READ radiusMd CONSTANT)

public:
    QColor surfaceColor() const { return QColor("#121a2d"); }
    QColor elevatedSurfaceColor() const { return QColor("#18233b"); }
    QColor borderColor() const { return QColor("#2d3b5d"); }
    QColor textColor() const { return QColor("#f3f7ff"); }
    QColor mutedTextColor() const { return QColor("#8e9bb7"); }
    QColor accentColor() const { return QColor("#56b3ff"); }
    QColor successColor() const { return QColor("#42c78f"); }
    QColor warningColor() const { return QColor("#ffb24d"); }
    QColor errorColor() const { return QColor("#ff6f7d"); }
    int radiusSm() const { return 10; }
    int radiusMd() const { return 16; }
};

class QmlComponentsTest : public QObject
{
    Q_OBJECT

private slots:
    void resultViewDerivesRawTextFromResultData();
    void resultViewSummaryDelegateHasPositiveHeight();
    void moduleSelectorToggleEmitsSelectedModulesChanged();
};

static QString qmlBasePath()
{
    return QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../src/frontend/qml");
}

static QQmlComponent createComponent(QQmlEngine &engine, const QString &relativePath)
{
    static FakeTheme theme;
    engine.rootContext()->setContextProperty("mainWindow", &theme);
    engine.addImportPath(qmlBasePath());
    return QQmlComponent(&engine, QUrl::fromLocalFile(qmlBasePath() + "/" + relativePath));
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

void QmlComponentsTest::resultViewDerivesRawTextFromResultData()
{
    QQmlEngine engine;
    QQmlComponent component = createComponent(engine, "components/ResultView.qml");
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QVariantMap module;
    module.insert("name", "network");
    module.insert("description", "network summary");
    module.insert("level", "ok");

    QVariantMap result;
    result.insert("network", module);

    QVERIFY(instance->setProperty("resultData", result));
    QCoreApplication::processEvents();

    const QString resultText = instance->property("resultText").toString();
    QVERIFY2(!resultText.isEmpty(), "resultText should be derived when resultData is assigned directly");
}

void QmlComponentsTest::resultViewSummaryDelegateHasPositiveHeight()
{
    QQmlEngine engine;
    QQmlComponent component = createComponent(engine, "components/ResultView.qml");
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    if (auto *item = qobject_cast<QQuickItem *>(instance.get())) {
        item->setWidth(800);
        item->setHeight(600);
    }

    QVariantMap module;
    module.insert("name", "network");
    module.insert("description", "network summary");
    module.insert("level", "ok");

    QVariantMap result;
    result.insert("network", module);

    QVERIFY(instance->setProperty("showRawJson", false));
    QVERIFY(instance->setProperty("resultData", result));
    QTest::qWait(50);

    const QVariantList keys = instance->property("resultKeys").toList();
    QCOMPARE(keys.size(), 1);
    QVERIFY2(instance->property("summaryItemCount").toInt() == 1,
             "summary repeater should create one item for one result entry");
}

void QmlComponentsTest::moduleSelectorToggleEmitsSelectedModulesChanged()
{
    QQmlEngine engine;
    QQmlComponent component = createComponent(engine, "components/ModuleSelector.qml");
    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> instance(component.create());
    QVERIFY2(instance != nullptr, qPrintable(component.errorString()));

    QSignalSpy propertySpy(instance.get(), SIGNAL(selectedModulesChanged()));
    QVERIFY2(propertySpy.isValid(), "selectedModulesChanged signal should exist");

    QVariantList modules;
    modules << "network" << "system";
    QVERIFY(QMetaObject::invokeMethod(instance.get(), "setModules", Q_ARG(QVariant, QVariant(modules))));

    propertySpy.clear();
    QVERIFY(QMetaObject::invokeMethod(instance.get(), "toggleModule", Q_ARG(QVariant, QVariant(QString("network")))));
    QCoreApplication::processEvents();

    QVERIFY2(propertySpy.count() > 0, "toggleModule should emit selectedModulesChanged so bindings update");
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("deepin-doctor");
    QmlComponentsTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "test_qml_components.moc"
