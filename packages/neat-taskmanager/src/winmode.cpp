#include "winmode.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace WinMode
{
// Local change: Windows mode is part of Wild OS (its wildos-winmode service
// and app registry). Here it is never present, so nothing is asked over
// D-Bus and no registry is read; what draws it stays hidden.
bool installedOnThisPc()
{
    return false;
}

Status status()
{
    return {};
}

QList<App> installed()
{
    return {};
}

QString appFor(const QList<App> &apps, const QString &program)
{
    const QString stem = program.section(QLatin1Char('\\'), -1).section(QLatin1Char('.'), 0, 0);
    for (const App &app : apps) {
        if (app.target.compare(program, Qt::CaseInsensitive) == 0) {
            return app.id;
        }
    }
    for (const App &app : apps) {
        if (app.target.section(QLatin1Char('\\'), -1).section(QLatin1Char('.'), 0, 0).compare(stem, Qt::CaseInsensitive) == 0) {
            return app.id;
        }
    }
    return {};
}

QString stateText(const QString &vm)
{
    if (vm == QLatin1String("running")) {
        return QCoreApplication::translate("WinMode", "Running");
    }
    if (vm == QLatin1String("paused") || vm == QLatin1String("pmsuspended")) {
        return QCoreApplication::translate("WinMode", "Paused");
    }
    if (vm == QLatin1String("saved")) {
        return QCoreApplication::translate("WinMode", "Saved to disk");
    }
    if (vm.isEmpty()) {
        return QCoreApplication::translate("WinMode", "Not set up");
    }
    return QCoreApplication::translate("WinMode", "Off");
}

QString idleText(const QString &whenIdle, int seconds)
{
    const QString after = seconds % 60 == 0 ? (seconds == 60 ? QCoreApplication::translate("WinMode", "1 minute") : QCoreApplication::translate("WinMode", "%1 minutes").arg(seconds / 60))
                                            : QCoreApplication::translate("WinMode", "%1 seconds").arg(seconds);
    if (whenIdle == QLatin1String("keep")) {
        return QCoreApplication::translate("WinMode", "Paused after %1").arg(after);
    }
    if (whenIdle == QLatin1String("save")) {
        return QCoreApplication::translate("WinMode", "Saved to disk after %1").arg(after);
    }
    return QCoreApplication::translate("WinMode", "Paused or saved after %1").arg(after);
}
}
