#pragma once
#include <QObject>
#include <QProcess>
#include <QQmlEngine>

// Exec.run(["cmd", "arg", ...]) from QML: starts a detached process.
class Exec : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    using QObject::QObject;
    Q_INVOKABLE bool run(const QStringList &cmd)
    {
        return !cmd.isEmpty() && QProcess::startDetached(cmd.first(), cmd.mid(1));
    }
};
