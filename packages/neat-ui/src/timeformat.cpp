#include "timeformat.h"

#include "clockformat.h"

#include <KConfigGroup>
#include <KSharedConfig>

#include <QLocale>

TimeFormat::TimeFormat(QObject *parent)
    : QObject(parent)
{
    read();
}

void TimeFormat::read()
{
    // Local change: no wildosrc; the clock follows the regional format.
    const int hours = 0;
    if (hours != m_hours) {
        m_hours = hours;
        Q_EMIT changed();
    }
}

QString TimeFormat::shortFormat() const
{
    return ClockFormat::rewrite(QLocale::system().timeFormat(QLocale::ShortFormat), m_hours);
}

QString TimeFormat::secondsFormat() const
{
    return ClockFormat::withSeconds(shortFormat());
}

QString TimeFormat::withoutMarker(const QDateTime &when) const
{
    return ClockFormat::withoutMarker(QLocale::system(), when.toLocalTime().time(), shortFormat());
}
