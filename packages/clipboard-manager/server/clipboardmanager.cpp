#include "clipboardmanager.h"
#include <QCoreApplication>
#include <QImage>
#include <QBuffer>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QProcess>
#include <QFile>
#include <QStandardPaths>
#include <QDateTime>
#include <QProcessEnvironment>
#include <signal.h>
#include <unistd.h>

// Runs wl-copy with the given extra args, writing `data` to its stdin.
static bool runWlCopy(const QStringList &extraArgs, const QByteArray &data)
{
    QProcess proc;
    proc.setProgram("wl-copy");
    proc.setArguments(extraArgs);
    proc.start();
    if (!proc.waitForStarted(1000)) {
        qWarning() << "Failed to start wl-copy" << extraArgs;
        return false;
    }
    proc.write(data);
    proc.closeWriteChannel();
    if (!proc.waitForFinished(2000)) {
        qWarning() << "wl-copy did not finish in time" << extraArgs;
        return false;
    }
    return true;
}

ClipboardManager::ClipboardManager(QObject *parent)
    : QObject(parent)
{
    startWatchers();
    setupWatcher();
}

ClipboardManager::~ClipboardManager()
{
    if (m_anyWatcher.state() == QProcess::Running) {
        m_anyWatcher.terminate();
        if (!m_anyWatcher.waitForFinished(1000))
            m_anyWatcher.kill();
    }
}

void ClipboardManager::startWatchers()
{
    const QString self = QCoreApplication::applicationFilePath();
    m_anyWatcher.setProgram("wl-paste");
    m_anyWatcher.setArguments({ "--watch", self, "--store-any" });
    m_anyWatcher.start();
    if (!m_anyWatcher.waitForStarted(2000)) {
        qWarning() << "Failed to start wl-paste watcher - is wl-clipboard installed and on PATH?";
    }
}

void ClipboardManager::setupWatcher()
{
    m_watcher = new QFileSystemWatcher(this);
    m_debounceTimer = new QTimer(this);
    m_debounceTimer->setInterval(200);
    m_debounceTimer->setSingleShot(true);
    connect(m_debounceTimer, &QTimer::timeout, this, &ClipboardManager::onHistoryFileChanged);

    QString dirPath = QFileInfo(HistoryStorage::historyPath()).absolutePath();
    if (!QDir().exists(dirPath))
        QDir().mkpath(dirPath);
    m_watcher->addPath(dirPath);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &ClipboardManager::onDirectoryChanged);

    QString filePath = HistoryStorage::historyPath();
    if (QFile::exists(filePath)) {
        m_watcher->addPath(filePath);
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this]() { m_debounceTimer->start(); });
    }
}

void ClipboardManager::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    QString filePath = HistoryStorage::historyPath();
    if (QFile::exists(filePath) && !m_watcher->files().contains(filePath)) {
        m_watcher->addPath(filePath);
        connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this]() { m_debounceTimer->start(); });
        m_debounceTimer->start();
    }
}

void ClipboardManager::onHistoryFileChanged()
{
    emit HistoryChanged();
}

void ClipboardManager::SetSelection(int index)
{
    HistoryEntry entry;
    if (!m_storage.takeAndBump(index, entry)) {
        qWarning() << "SetSelection: invalid index or lock failure" << index;
        return;
    }

    HistoryStorage::markIgnoreWindow(1500);

    if (entry.type == "text") {
        QByteArray bytes = entry.content.toUtf8();
        runWlCopy({}, bytes);
        runWlCopy({ "--primary" }, bytes);
    } else if (entry.type == "image") {
        QImage img;
        if (img.load(entry.content)) {
            QByteArray bytes;
            QBuffer buf(&bytes);
            buf.open(QIODevice::WriteOnly);
            img.save(&buf, "PNG");
            buf.close();
            runWlCopy({ "--type", "image/png" }, bytes);
            runWlCopy({ "--type", "image/png", "--primary" }, bytes);
        }
    }

    emit HistoryChanged();
}

void ClipboardManager::IgnoreNext()
{
    HistoryStorage::markIgnoreWindow(1500);
}

void ClipboardManager::DeleteEntry(int index)
{
    m_storage.removeEntry(index);
    emit HistoryChanged();
}

// -------- CORE CHANGE: Only emit the D-Bus signal --------
void ClipboardManager::Show(int x, int y)
{
    qWarning() << "Show() invoked with" << x << y;
    emit ShowRequested(x, y);
}
