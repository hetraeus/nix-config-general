#ifndef HISTORYENTRY_H
#define HISTORYENTRY_H

#include <QString>
#include <QDBusArgument>

struct HistoryEntry {
    QString type;
    QString content;
    QString timestamp;
    QString mimeType;   // for image entries, stores the original MIME type
};

Q_DECLARE_METATYPE(HistoryEntry)

QDBusArgument &operator<<(QDBusArgument &arg, const HistoryEntry &entry);
const QDBusArgument &operator>>(const QDBusArgument &arg, HistoryEntry &entry);

#endif
