#include "historystorage.h"
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QDir>
#include <QUuid>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QLockFile>
#include <QDebug>

HistoryStorage::HistoryStorage(QObject *parent) : QObject(parent)
{
    QDir().mkpath(cacheDir());
    QDir().mkpath(thumbDir());
    QDir().mkpath(QFileInfo(historyPath()).absolutePath());

    // Prune stale image entries (files wiped from XDG_RUNTIME_DIR on reboot)
    // and persist the pruning immediately, so the client — which reads
    // history.json directly — doesn't keep rendering dead "🖼 Image" rows.
    QDir().mkpath(QFileInfo(lockPath()).absolutePath());
    QLockFile lock(lockPath());
    lock.setStaleLockTime(5000);
    if (lock.tryLock(2000)) {
        load();
        if (m_droppedOnLoad && !m_loadFailed)
            save();
        lock.unlock();
    } else {
        // Someone else holds the lock; load without saving. The next writer
        // will pick up the pruning via its own load()-then-save().
        load();
    }
}

QString HistoryStorage::historyPath()
{
    return QDir::home().filePath(".cache/clipboard-manager/history.json");
}

QString HistoryStorage::cacheDir()
{
    QString runtime = QProcessEnvironment::systemEnvironment().value("XDG_RUNTIME_DIR");
    if (runtime.isEmpty())
        runtime = QDir::temp().path();
    return runtime + "/clipboard-manager/images";
}

QString HistoryStorage::thumbDir()
{
    QString runtime = QProcessEnvironment::systemEnvironment().value("XDG_RUNTIME_DIR");
    if (runtime.isEmpty())
        runtime = QDir::temp().path();
    return runtime + "/clipboard-manager/thumbnails";
}

QString HistoryStorage::ignoreMarkerPath()
{
    return QDir::home().filePath(".cache/clipboard-manager/.ignore-until");
}

QString HistoryStorage::lockPath()
{
    return QDir::home().filePath(".cache/clipboard-manager/.history.lock");
}

void HistoryStorage::markIgnoreWindow(int ms)
{
    QDir().mkpath(QFileInfo(ignoreMarkerPath()).absolutePath());
    QFile f(ignoreMarkerPath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qint64 deadline = QDateTime::currentMSecsSinceEpoch() + ms;
        f.write(QByteArray::number(deadline));
    } else {
        qWarning() << "Failed to create ignore marker file";
    }
}

bool HistoryStorage::shouldIgnoreNow()
{
    QFile f(ignoreMarkerPath());
    if (!f.open(QIODevice::ReadOnly)) {
        return false;
    }
    bool ok = false;
    qint64 deadline = f.readAll().trimmed().toLongLong(&ok);
    f.close();
    return ok && QDateTime::currentMSecsSinceEpoch() <= deadline;
}

void HistoryStorage::load()
{
    QFile file(historyPath());
    if (!file.open(QIODevice::ReadOnly)) {
        m_loadFailed = false;
        return;
    }
    QByteArray data = file.readAll();
    if (data.isEmpty()) {
        m_loadFailed = false;
        return;
    }

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "history.json exists but failed to parse - leaving it untouched to avoid data loss:"
                    << parseError.errorString();
        m_loadFailed = true;
        return;
    }
    m_loadFailed = false;
    QJsonArray arr = doc.object().value("entries").toArray();
    m_entries.clear();
    m_droppedOnLoad = false;
    for (const auto &item : arr) {
        QJsonObject obj = item.toObject();
        HistoryEntry e;
        e.type = obj.value("type").toString();
        e.content = obj.value("content").toString();
        e.timestamp = obj.value("timestamp").toString();
        e.mimeType = obj.value("mimeType").toString();

        // Images live in XDG_RUNTIME_DIR (tmpfs, wiped on reboot) while
        // history.json lives in ~/.cache. After a reboot every image entry
        // here points at a nonexistent file; without pruning they render as
        // bare "🖼 Image" rows forever.
        if (e.type == "image" && !QFile::exists(e.content)) {
            m_droppedOnLoad = true;
            continue;
        }

        m_entries.append(e);
    }
}

void HistoryStorage::save()
{
    if (m_loadFailed) {
        qWarning() << "Refusing to save: history.json is in a corrupted state at"
                    << historyPath() << "- fix or remove it manually to recover.";
        return;
    }

    QJsonArray arr;
    for (const auto &e : m_entries) {
        QJsonObject obj;
        obj["type"] = e.type;
        obj["content"] = e.content;
        obj["timestamp"] = e.timestamp;
        if (!e.mimeType.isEmpty())
            obj["mimeType"] = e.mimeType;   // write MIME type if present
        arr.append(obj);
    }
    QJsonObject root;
    root["entries"] = arr;

    const QString finalPath = historyPath();
    const QString tmpPath = finalPath + ".tmp";

    QFile tmpFile(tmpPath);
    if (!tmpFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "Failed to write" << tmpPath << ":" << tmpFile.errorString();
        return;
    }
    tmpFile.write(QJsonDocument(root).toJson());
    tmpFile.close();

    QFile::remove(finalPath);
    if (!QFile::rename(tmpPath, finalPath)) {
        qWarning() << "Failed to atomically replace history.json";
    }
}

void HistoryStorage::addEntry(const QString &type, const QString &content, const QString &mimeType)
{
    if (content.trimmed().isEmpty())
        return;

    QDir().mkpath(QFileInfo(lockPath()).absolutePath());
    QLockFile lock(lockPath());
    lock.setStaleLockTime(5000);
    if (!lock.tryLock(2000)) {
        qWarning() << "Could not acquire history lock in time, dropping this entry rather than risk a racing write";
        return;
    }

    load();
    if (m_loadFailed) {
        lock.unlock();
        return;
    }

    // Check for exact duplicate (same type and content) anywhere in the list
    for (int i = 0; i < m_entries.size(); ++i) {
        const HistoryEntry &e = m_entries.at(i);
        if (e.type == type && e.content == content) {
            // Found duplicate: bump it to the top
            HistoryEntry dup = m_entries.takeAt(i);
            dup.timestamp = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
            // Update MIME type if the new one provides it and the old one is empty
            if (!mimeType.isEmpty() && dup.mimeType.isEmpty()) {
                dup.mimeType = mimeType;
            }
            m_entries.prepend(dup);
            save();
            lock.unlock();
            return;
        }
    }

    // Not a duplicate: add new entry
    HistoryEntry e;
    e.type = type;
    e.content = content;
    e.timestamp = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
    e.mimeType = mimeType;
    m_entries.prepend(e);
    while (m_entries.size() > MAX_ENTRIES) {
        m_entries.takeLast();
    }
    save();
    lock.unlock();

    if (type == "image") {
        manageImageCache(content);
    }
}

QString HistoryStorage::saveImageEntry(const QImage &img)
{
    QDir().mkpath(cacheDir());
    QDir().mkpath(thumbDir());

    QString fileName = QUuid::createUuid().toString(QUuid::WithoutBraces) + ".png";
    QString path = cacheDir() + "/" + fileName;
    if (!img.save(path, "PNG"))
        return QString();

    QImage thumb = img.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    thumb.save(thumbDir() + "/" + fileName, "PNG");

    return path;
}

void HistoryStorage::manageImageCache(const QString &imagePath)
{
    QStringList imageFiles;
    for (const auto &e : m_entries) {
        if (e.type == "image" && QFile::exists(e.content))
            imageFiles.append(e.content);
    }
    while (imageFiles.size() > MAX_IMAGES) {
        QString oldest = imageFiles.takeLast();
        QFile::remove(oldest);
        QString thumb = thumbDir() + "/" + QFileInfo(oldest).fileName();
        QFile::remove(thumb);
    }
}

void HistoryStorage::clear()
{
    QDir().mkpath(QFileInfo(lockPath()).absolutePath());
    QLockFile lock(lockPath());
    lock.setStaleLockTime(5000);
    if (!lock.tryLock(2000)) {
        qWarning() << "Could not acquire history lock, clear() aborted";
        return;
    }
    m_entries.clear();
    m_loadFailed = false;
    save();
    lock.unlock();
}

bool HistoryStorage::takeAndBump(int index, HistoryEntry &out)
{
    QDir().mkpath(QFileInfo(lockPath()).absolutePath());
    QLockFile lock(lockPath());
    lock.setStaleLockTime(5000);
    if (!lock.tryLock(2000)) {
        qWarning() << "Could not acquire history lock, takeAndBump() aborted";
        return false;
    }

    // Re-read while holding the lock so the index refers to the exact view
    // we are about to mutate, even if another process (the --store-any
    // watcher, another SetSelection, etc.) wrote in between.
    load();
    if (m_loadFailed || index < 0 || index >= m_entries.size()) {
        lock.unlock();
        return false;
    }

    out = m_entries.at(index);

    // Match the old bumpEntry() semantics: index 0 is already at the top,
    // so there is nothing to move. The caller still gets the entry via `out`.
    if (index > 0) {
        HistoryEntry moved = m_entries.takeAt(index);
        moved.timestamp = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
        m_entries.prepend(moved);
        save();
    }

    lock.unlock();
    return true;
}

void HistoryStorage::removeEntry(int index)
{
    QDir().mkpath(QFileInfo(lockPath()).absolutePath());
    QLockFile lock(lockPath());
    lock.setStaleLockTime(5000);
    if (!lock.tryLock(2000)) {
        qWarning() << "Could not acquire history lock, removeEntry() aborted";
        return;
    }

    // Re-read from disk while holding the lock so we don't operate on a stale view.
    load();
    if (m_loadFailed || index < 0 || index >= m_entries.size()) {
        lock.unlock();
        return;
    }

    HistoryEntry entry = m_entries.takeAt(index);

    // If it was an image, clean up both the full-size file and its thumbnail.
    if (entry.type == "image" && !entry.content.isEmpty()) {
        QFile::remove(entry.content);
        const QString thumb = thumbDir() + "/" + QFileInfo(entry.content).fileName();
        QFile::remove(thumb);
    }

    save();
    lock.unlock();
}
