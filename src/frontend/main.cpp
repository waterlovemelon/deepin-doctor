#include "BackendProxy.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGlobal>

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("deepin-doctor");
    QGuiApplication::setApplicationVersion("0.1.0");

    QQmlApplicationEngine engine;
    BackendProxy backendProxy;
    engine.rootContext()->setContextProperty("backend", &backendProxy);
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
