#include "BackendProxy.h"
#include "LogBackendProxy.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGlobal>
#include <QQuickStyle>

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("deepin-doctor");
    QGuiApplication::setApplicationVersion("0.1.0");
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;
    BackendProxy backendProxy;
    engine.rootContext()->setContextProperty("backend", &backendProxy);
    LogBackendProxy logBackendProxy;
    engine.rootContext()->setContextProperty("logBackend", &logBackendProxy);
    engine.rootContext()->setContextProperty("QtVersionMajor", QT_VERSION_MAJOR);

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    const QUrl url(u"qrc:/qt/qml/DeepinDoctor/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
#else
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
#endif

    engine.load(url);

    return app.exec();
}
