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

    // NEW: called by the hotkey bind via dbus-send.
    // Writes a show request and ensures a client is running.
    void Show(int x, int y);

signals:
    void HistoryChanged();
    void ShowRequested(int x, int y);   // declared for interface completeness

private slots:
    void onHistoryFileChanged();
    void onDirectoryChanged(const QString &path);

private:
    void startWatchers();
    void setupWatcher();

    HistoryStorage m_storage;
    QProcess m_anyWatcher;
    QFileSystemWatcher *m_watcher;
    QTimer *m_debounceTimer;
};

#endif
