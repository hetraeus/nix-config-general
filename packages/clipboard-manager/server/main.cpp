#include <QCoreApplication>
#include <QDBusMetaType>
#include <QDBusConnection>
#include <QDBusError>
#include <QFile>
#include <QImage>
#include <QSvgRenderer>   // add this
#include <QPainter>       // add this
#include <QProcess>
#include <QDebug>
#include "clipboardmanager.h"
#include "historyentry.h"
#include "clipboard_manager_interface.h"

// Helper: Try to load image data, with SVG fallback
static QImage loadImageFromData(const QByteArray &data, const QString &mimeType)
{
    QImage img;
    
    // First try normal QImage loading (works for PNG, JPEG, BMP, etc.)
    if (img.loadFromData(data)) {
        return img;
    }
    
    // If that fails and it's an SVG, render it manually
    if (mimeType == "image/svg+xml") {
        QSvgRenderer renderer(data);
        if (renderer.isValid()) {
            QSize size = renderer.defaultSize();
            if (size.isEmpty()) {
                size = QSize(256, 256);  // fallback size
            }
            QImage svgImg(size, QImage::Format_ARGB32);
            svgImg.fill(Qt::transparent);
            QPainter painter(&svgImg);
            renderer.render(&painter);
            painter.end();
            return svgImg;
        }
    }
    
    return QImage();  // failed
}

static bool hasPasswordManagerHint()
{
    QProcess proc;
    proc.setProgram("wl-paste");
    proc.setArguments({ "--list-types" });
    proc.start();
    if (!proc.waitForFinished(1000)) {
        qWarning() << "Failed to run wl-paste --list-types";
        return false;
    }
    QString output = proc.readAllStandardOutput();
    return output.contains("x-kde-passwordManagerHint");
}

static QStringList getClipboardTypes()
{
    QProcess proc;
    proc.setProgram("wl-paste");
    proc.setArguments({ "--list-types" });
    proc.start();
    if (!proc.waitForFinished(1000)) {
        qWarning() << "Failed to run wl-paste --list-types";
        return QStringList();
    }
    QString output = proc.readAllStandardOutput();
    return output.split('\n', Qt::SkipEmptyParts);
}

static QString getFirstImageType(const QStringList &types)
{
    for (const QString &t : types) {
        if (t.startsWith("image/"))
            return t;
    }
    return QString();
}

// The only watcher entry point – stores image if available, otherwise plain text.
static int storeAny()
{
    if (HistoryStorage::shouldIgnoreNow())
        return 0;

    if (hasPasswordManagerHint()) {
        qDebug() << "Skipping with password manager hint";
        return 0;
    }

    QStringList types = getClipboardTypes();
    if (types.isEmpty())
        return 0;

    // Try to store image first
    QString imageMime = getFirstImageType(types);
    if (!imageMime.isEmpty()) {
        QProcess proc;
        proc.setProgram("wl-paste");
        proc.setArguments({ "--type", imageMime });
        proc.start();
        if (!proc.waitForStarted(1000)) {
            qWarning() << "Failed to start wl-paste for image";
            return 1;
        }
        proc.closeWriteChannel();
        if (!proc.waitForFinished(2000)) {
            qWarning() << "wl-paste (image) did not finish in time";
            return 1;
        }
        QByteArray data = proc.readAllStandardOutput();
        if (data.isEmpty())
            return 0;

        // Use the new helper instead of QImage::loadFromData directly
        QImage img = loadImageFromData(data, imageMime);
        if (img.isNull()) {
            qWarning() << "Failed to decode image data (mime:" << imageMime << ")";
            return 1;
        }

        HistoryStorage storage;
        QString path = storage.saveImageEntry(img);
        if (path.isEmpty())
            return 1;
        storage.addEntry("image", path, imageMime);   // <-- HERE
        return 0;
    }

    // Fallback to plain text
    if (types.contains("text/plain")) {
        QProcess proc;
        proc.setProgram("wl-paste");
        proc.setArguments({ "--type", "text/plain" });
        proc.start();
        if (!proc.waitForStarted(1000)) {
            qWarning() << "Failed to start wl-paste for text";
            return 1;
        }
        proc.closeWriteChannel();
        if (!proc.waitForFinished(2000)) {
            qWarning() << "wl-paste (text) did not finish in time";
            return 1;
        }
        QByteArray data = proc.readAllStandardOutput();
        if (data.isEmpty())
            return 0;

        QString text = QString::fromUtf8(data);
        QString trimmed = text.trimmed();
        if (trimmed.isEmpty())
            return 0;

        // skip only single ASCII letters/digits, not emojis
        if (trimmed.length() == 1) {
            QChar c = trimmed.at(0);
            if (c.unicode() < 128 && (c.isLetterOrNumber() || c.isPunct()))
                return 0;
        }

        HistoryStorage storage;
        storage.addEntry("text", text);
        return 0;
    }

    return 0;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName("ClipboardManager");
    app.setOrganizationName("Custom");

    const QStringList args = app.arguments();

    // Only --store-any is supported now
    if (args.contains("--store-any"))
        return storeAny();

    // No other --store-* arguments are accepted; if they appear, just ignore them.
    // (You can optionally print a warning.)

    qDBusRegisterMetaType<HistoryEntry>();
    qRegisterMetaType<QList<HistoryEntry>>();
    qDBusRegisterMetaType<QList<HistoryEntry>>();

    ClipboardManager manager;

    if (!QDBusConnection::sessionBus().registerService("org.clipboard.Manager")) {
        qWarning() << "Failed to register D-Bus service";
        return 1;
    }
    if (!QDBusConnection::sessionBus().registerObject("/", &manager,
                                                       QDBusConnection::ExportAllSlots |
                                                       QDBusConnection::ExportAllSignals)) {
        qWarning() << "Failed to register D-Bus object";
        return 1;
    }

    qDebug() << "Clipboard manager running with single watcher (--store-any)";
    return app.exec();
}
