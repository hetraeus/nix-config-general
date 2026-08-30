#include "historyentry.h"

QDBusArgument &operator<<(QDBusArgument &arg, const HistoryEntry &entry)
{
    arg.beginStructure();
    arg << entry.type << entry.content << entry.timestamp;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, HistoryEntry &entry)
{
    arg.beginStructure();
    arg >> entry.type >> entry.content >> entry.timestamp;
    arg.endStructure();
    return arg;
}
