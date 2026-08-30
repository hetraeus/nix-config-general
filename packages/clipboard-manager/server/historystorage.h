#ifndef HISTORYSTORAGE_H
#define HISTORYSTORAGE_H

#include <QObject>
#include <QList>
#include <QImage>
#include "historyentry.h"

class HistoryStorage : public QObject
{
    Q_OBJECT
public:
    explicit HistoryStorage(QObject *parent = nullptr);

    void load();
    void save();
    void addEntry(const QString &type, const QString &content, const QString &mimeType = QString());
    QList<HistoryEntry> entries() const { return m_entries; }
    void clear();
    void bumpEntry(int index);

    // Saves a full-size image + thumbnail to disk and returns the path to
    // the full-size image (suitable as the `content` for addEntry), or an
    // empty string on failure.
    QString saveImageEntry(const QImage &img);

    static QString cacheDir();
    static QString thumbDir();
    static QString historyPath();

    // Cross-process advisory lock guarding history.json.
    static QString lockPath();

    // Short "ignore window" so that SetSelection doesn't get re‑captured.
    static void markIgnoreWindow(int ms);
    static bool shouldIgnoreNow();

private:
    void manageImageCache(const QString &imagePath);
    static QString ignoreMarkerPath();

    QList<HistoryEntry> m_entries;
    bool m_loadFailed = false;
    static const int MAX_ENTRIES = 100;
    static const int MAX_IMAGES = 10;
};

#endif
