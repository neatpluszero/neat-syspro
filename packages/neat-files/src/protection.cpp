#include "protection.h"

#include <KConfigGroup>

namespace
{
const char group[] = "RemoveDetails";
}

Protection *Protection::instance()
{
    static Protection *protection = new Protection;
    return protection;
}

Protection *Protection::create(QQmlEngine *, QJSEngine *)
{
    auto protection = instance();
    QJSEngine::setObjectOwnership(protection, QJSEngine::CppOwnership);
    return protection;
}

Protection::Protection(QObject *parent)
    : QObject(parent)
    , m_config(KSharedConfig::openConfig(QStringLiteral("neatfilesrc")))
{
    // Local change: Wild OS switches these in /etc/wildos/advanced-protection.
    // Here both are simply available wherever their tools are installed.
}

void Protection::read()
{
}

void Protection::write(const char *key, bool value)
{
    KConfigGroup(m_config, QString::fromLatin1(group)).writeEntry(key, value);
    m_config->sync();
    Q_EMIT choicesChanged();
}

bool Protection::removeLocation() const
{
    return KConfigGroup(m_config, QString::fromLatin1(group)).readEntry("Location", true);
}

void Protection::setRemoveLocation(bool on)
{
    write("Location", on);
}

bool Protection::removeDevice() const
{
    return KConfigGroup(m_config, QString::fromLatin1(group)).readEntry("Device", true);
}

void Protection::setRemoveDevice(bool on)
{
    write("Device", on);
}

bool Protection::removeAuthors() const
{
    return KConfigGroup(m_config, QString::fromLatin1(group)).readEntry("Authors", true);
}

void Protection::setRemoveAuthors(bool on)
{
    write("Authors", on);
}

bool Protection::safeBoxExplained() const
{
    return KConfigGroup(m_config, QStringLiteral("SafeBox")).readEntry("Explained", false);
}

void Protection::setSafeBoxExplained(bool done)
{
    KConfigGroup(m_config, QStringLiteral("SafeBox")).writeEntry("Explained", done);
    m_config->sync();
    Q_EMIT choicesChanged();
}
