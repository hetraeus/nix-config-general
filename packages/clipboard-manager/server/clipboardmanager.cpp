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

static QString watcherPidPath()
{
    return QDir::home().filePath(".cache/clipboard-manager/watcher.pid");
}

// Runs wl-copy with the given extra args, writing `data` to its stdin.
// Used to set both the regular clipboard and the primary selection so
// that Ctrl+V *and* middle-click / mouse paste both pick up the entry.
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
    {
      QFile f(showRequestPath());
      if (f.open(QIODevice::WriteOnly | QIODevice::Append))
          f.close();
    }
    killExistingWatchers();
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
    QFile::remove(watcherPidPath());
}

void ClipboardManager::killExistingWatchers()
{
    QFile pidFile(watcherPidPath());
    if (!pidFile.open(QIODevice::ReadOnly))
        return;

    QByteArray data = pidFile.readAll().trimmed();
    pidFile.close();

    bool ok;
    pid_t oldPid = data.toInt(&ok);
    if (!ok || oldPid <= 0)
        return;

    // Check existence (signal 0)
    if (kill(oldPid, 0) == 0) {
        // Terminate politely
        kill(oldPid, SIGTERM);
        // Wait up to 1 second
        for (int i = 0; i < 10; ++i) {
            if (kill(oldPid, 0) != 0)
                break;
            usleep(100000);
        }
        // If still alive, force kill
        if (kill(oldPid, 0) == 0)
            kill(oldPid, SIGKILL);
    }
    QFile::remove(watcherPidPath());
}

void ClipboardManager::startWatchers()
{
    const QString self = QCoreApplication::applicationFilePath();

    m_anyWatcher.setProgram("wl-paste");
    m_anyWatcher.setArguments({ "--watch", self, "--store-any" });
    m_anyWatcher.start();

    if (!m_anyWatcher.waitForStarted(2000)) {
        qWarning() << "Failed to start wl-paste watcher - is wl-clipboard installed and on PATH?";
        return;
    }

    // Save PID
    qint64 pid = m_anyWatcher.processId();
    QFile pidFile(watcherPidPath());
    if (pidFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        pidFile.write(QByteArray::number(pid));
        pidFile.close();
    } else {
        qWarning() << "Could not write watcher PID file";
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
    if (!QDir().exists(dirPath)) {
        QDir().mkpath(dirPath);
    }
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
    m_storage.load();
    auto entries = m_storage.entries();
    if (index < 0 || index >= entries.size()) {
        qWarning() << "SetSelection: invalid index" << index;
        return;
    }

    m_storage.bumpEntry(index);

    const QList<HistoryEntry> refreshedEntries = m_storage.entries();
    const HistoryEntry &entry = refreshedEntries.first();

    HistoryStorage::markIgnoreWindow(1500);

    if (entry.type == "text") {
        QByteArray bytes = entry.content.toUtf8();
        if (!runWlCopy({}, bytes)) {
            qWarning() << "Failed to set clipboard selection for text";
        }
        if (!runWlCopy({ "--primary" }, bytes)) {
            qWarning() << "Failed to set primary selection for text";
        }
    } else if (entry.type == "image") {
        QImage img;
        if (img.load(entry.content)) {
            QByteArray bytes;
            QBuffer buf(&bytes);
            buf.open(QIODevice::WriteOnly);
            img.save(&buf, "PNG");
            buf.close();

            if (!runWlCopy({ "--type", "image/png" }, bytes)) {
                qWarning() << "Failed to set clipboard selection for image";
            }
            if (!runWlCopy({ "--type", "image/png", "--primary" }, bytes)) {
                qWarning() << "Failed to set primary selection for image";
            }
        } else {
            qWarning() << "Failed to load image from" << entry.content;
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

static QString xdgRuntimeDir()
{
    QString r = QProcessEnvironment::systemEnvironment().value("XDG_RUNTIME_DIR");
    if (r.isEmpty())
        r = QDir::temp().path();
    return r;
}

QString ClipboardManager::runtimeDir()
{
    return xdgRuntimeDir() + "/clipboard-manager";
}

QString ClipboardManager::showRequestPath()
{
    return runtimeDir() + "/show-request";
}

QString ClipboardManager::clientLockPath()
{
    return xdgRuntimeDir() + "/clipboard-client.lock";
}

void ClipboardManager::Show(int x, int y)
{
    qWarning() << "Show() invoked with" << x << y;
    writeShowRequest(x, y);
    ensureClientRunning();
}

void ClipboardManager::writeShowRequest(int x, int y)
{
    qWarning() << "writeShowRequest: entering, path=" << showRequestPath();

    QDir().mkpath(runtimeDir());

    QFile f(showRequestPath());
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "writeShowRequest: open failed:" << f.errorString();
        return;
    }

    ++m_showSeq;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QByteArray data = QByteArray::number(m_showSeq) + " " +
                      QByteArray::number(now) + " " +
                      QByteArray::number(x) + " " +
                      QByteArray::number(y) + "\n";
    f.write(data);
    f.close();

    qWarning() << "writeShowRequest: wrote" << data.trimmed();
}

void ClipboardManager::ensureClientRunning()
{
    // Non-blockingly test the client lock. If it succeeds, no client
    // is holding it, so we spawn one. If it fails, a client is alive
    // and will pick up the show request from the file.
    QProcess flock;
    flock.setProgram("flock");
    flock.setArguments({ "-n", clientLockPath(), "-c", "true" });
    flock.start();
    if (!flock.waitForStarted(1000)) {
        qWarning() << "Failed to start flock - is util-linux on PATH?";
        return;
    }
    flock.waitForFinished(1000);
    if (flock.exitCode() != 0)
        return;  // lock held -> client is running

    const QString client = QStandardPaths::findExecutable("clipboard-client");
    if (client.isEmpty()) {
        qWarning() << "clipboard-client not found in PATH";
        return;
    }
    QProcess::startDetached(client, {});
}
