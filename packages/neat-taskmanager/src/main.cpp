#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>

namespace
{
const QString serviceName = QStringLiteral("io.github.neatpluszero.NeatTaskManager");
const QString objectPath = QStringLiteral("/TaskManager");
}

// Ctrl+Shift+Esc a second time brings the open Task Manager forward, on the
// page asked for, instead of opening another, as Windows does.
class Remote : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "io.github.neatpluszero.NeatTaskManager")

public:
    explicit Remote(QQmlApplicationEngine *engine)
        : QObject(engine)
        , m_engine(engine)
    {
    }

public Q_SLOTS:
    Q_SCRIPTABLE void show(const QString &page)
    {
        const auto roots = m_engine->rootObjects();
        if (roots.isEmpty()) {
            return;
        }
        QObject *root = roots.constFirst();
        if (!page.isEmpty()) {
            QMetaObject::invokeMethod(root, "showPage", Q_ARG(QVariant, page));
        }
        if (auto window = qobject_cast<QQuickWindow *>(root)) {
            if (window->visibility() == QWindow::Minimized) {
                window->showNormal();
            }
            window->show();
            window->raise();
            window->requestActivate();
        }
    }

private:
    QQmlApplicationEngine *m_engine;
};

// Local change: settings saved under the app's Wild OS names are carried
// over once, the first time it runs under its new name. The old files are
// left alone (on Wild OS they still belong to Wild OS's own Files).
void migrateConfig(const QString &oldName, const QString &newName, const QList<QPair<QByteArray, QByteArray>> &renames)
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
    QFile from(dir + QLatin1Char('/') + oldName);
    QFile to(dir + QLatin1Char('/') + newName);
    if (to.exists() || !from.open(QIODevice::ReadOnly)) {
        return;
    }
    QByteArray text = from.readAll();
    for (const auto &rename : renames) {
        text.replace(rename.first, rename.second);
    }
    QDir().mkpath(dir);
    if (to.open(QIODevice::WriteOnly)) {
        to.write(text);
    }
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("neat-taskmanager"));
    migrateConfig(QStringLiteral("wildos-taskmanagerrc"), QStringLiteral("neat-taskmanagerrc"), {});
    // Remembered window sizes, for all three apps at once: the file is shared.
    migrateConfig(QStringLiteral("wildoswindowsrc"), QStringLiteral("neatwindowsrc"),
                  {{"[wildos-files]", "[neat-files]"}, {"[wildos-taskmanager]", "[neat-taskmanager]"}, {"[wildos-remote]", "[neat-remote]"}});
    app.setOrganizationDomain(QStringLiteral("neatpluszero.github.io"));
    app.setApplicationDisplayName(QStringLiteral("Task Manager"));
    app.setApplicationVersion(QStringLiteral(NEAT_TASKMANAGER_VERSION));
    app.setDesktopFileName(QStringLiteral("io.github.neatpluszero.NeatTaskManager"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("io.github.neatpluszero.NeatTaskManager")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Task Manager"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption pageOption(QStringLiteral("page"),
                                  QStringLiteral("Open on this page: processes, performance, startup, services or settings."),
                                  QStringLiteral("page"));
    parser.addOption(pageOption);
    parser.process(app);
    const QString page = parser.value(pageOption);

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected() && bus.interface()->isServiceRegistered(serviceName)) {
        auto message = QDBusMessage::createMethodCall(serviceName, objectPath, serviceName, QStringLiteral("show"));
        message << page;
        bus.call(message, QDBus::Block, 5000);
        return 0;
    }

    QQuickStyle::setStyle(QStringLiteral("Basic"));
    // The window draws its own title bar and rounded glass sheet.
    QQuickWindow::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;
    engine.setInitialProperties({{QStringLiteral("requestedPage"), page}});
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
        QCoreApplication::exit(1);
    }, Qt::QueuedConnection);
    engine.loadFromModule("Neat.TaskManager", "Main");

    if (bus.isConnected()) {
        bus.registerObject(objectPath, new Remote(&engine), QDBusConnection::ExportScriptableSlots);
        bus.registerService(serviceName);
    }
    return app.exec();
}

#include "main.moc"
