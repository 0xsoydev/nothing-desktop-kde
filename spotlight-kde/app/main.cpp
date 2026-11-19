#include <KGlobalAccel>
#include <QAction>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

// Registers a global shortcut (rebindable in System Settings > Shortcuts > Spotlight) that calls root.toggle().
static void bind(QAction &action, const char *name, const QString &text, QKeySequence key, QObject *root)
{
    action.setObjectName(QString::fromLatin1(name));
    action.setText(text);
    KGlobalAccel::self()->setDefaultShortcut(&action, {key});
    KGlobalAccel::self()->setShortcut(&action, {key});
    QObject::connect(&action, &QAction::triggered, root, [root] { QMetaObject::invokeMethod(root, "toggle"); });
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("spotlight-kde"));
    app.setApplicationDisplayName(QStringLiteral("Spotlight"));
    app.setDesktopFileName(QStringLiteral("spotlight-kde"));
    // Stay resident while hidden; KRunner/KIO jobs releasing their event-loop locks would otherwise quit us.
    app.setQuitOnLastWindowClosed(false);
    app.setQuitLockEnabled(false);

    QQmlApplicationEngine engine;
    engine.loadFromModule("org.zer0day.spotlight", "Main");
    engine.loadFromModule("org.zer0day.spotlight", "PowerMenu");
    if (engine.rootObjects().size() != 2)
        return 1;

    QAction spotlight, power;
    bind(spotlight, "toggle", QStringLiteral("Toggle Spotlight"), QKeySequence(Qt::ALT | Qt::Key_Space), engine.rootObjects()[0]);
    bind(power, "power", QStringLiteral("Power Menu"), QKeySequence(Qt::META | Qt::SHIFT | Qt::Key_P), engine.rootObjects()[1]);

    return app.exec();
}
