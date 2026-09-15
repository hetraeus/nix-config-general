#ifndef CLIPBOARDMANAGER_H
#define CLIPBOARDMANAGER_H

#include <QObject>
#include <QProcess>
#include <QFileSystemWatcher>
#include <QTimer>
#include "historystorage.h"

class ClipboardManager : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.clipboard.Manager")

public:
    explicit ClipboardManager(QObject *parent = nullptr);
    ~ClipboardManager();

public slots:
    QList<HistoryEntry> GetHistory() { m_storage.load(); return m_storage.entries(); }
    void SetSelection(int index);
    void DeleteEntry(int index);
    void IgnoreNext();

signals:
    void HistoryChanged();

private slots:
    void onHistoryFileChanged();
    void onDirectoryChanged(const QString &path);

private:
    void startWatchers();
    void setupWatcher();
    void killExistingWatchers();   // <-- declared here

    HistoryStorage m_storage;
    QProcess m_anyWatcher;
    QFileSystemWatcher *m_watcher;
    QTimer *m_debounceTimer;
};

#endif
