#pragma once

#include <QHash>
#include <QString>
#include <QUrl>

// Local change: where items that are not plain local files really are on
// this PC, as KIO reports it (UDS_LOCAL_PATH): files in the Recycle Bin
// above all. Folder listings and item details fill it in; thumbnails and
// opening use it, since apps and the thumbnailers want a real file. Main
// thread only.
namespace LocalPaths
{
inline QHash<QUrl, QString> &known()
{
    static QHash<QUrl, QString> paths;
    return paths;
}

inline void remember(const QUrl &url, const QString &path)
{
    if (!url.isLocalFile() && !path.isEmpty()) {
        // A bin can hold thousands of items over a session; old answers are
        // cheap to ask for again.
        if (known().size() > 20000) {
            known().clear();
        }
        known().insert(url, path);
    }
}

// The file behind the address, or the address itself when it is already a
// local file or nothing is known about it.
inline QUrl resolve(const QUrl &url)
{
    if (url.isLocalFile()) {
        return url;
    }
    const auto it = known().constFind(url);
    return it != known().constEnd() ? QUrl::fromLocalFile(*it) : url;
}

inline bool isLocal(const QUrl &url)
{
    return resolve(url).isLocalFile();
}
}
