use crate::storage::HistoryStorage;
use crate::wl;
use anyhow::{Context, Result};
use std::sync::{Arc, Mutex};
use std::time::Duration;
use wl_clipboard_rs::copy::ClipboardType;
use zbus::{interface, object_server::SignalEmitter, Connection};

pub struct Manager {
    // Arc so the blocking lock/load/save work can be moved into
    // `spawn_blocking` without holding a std MutexGuard across an await.
    storage: Arc<Mutex<HistoryStorage>>,
}

impl Manager {
    pub fn new() -> Self {
        Self {
            storage: Arc::new(Mutex::new(HistoryStorage::new())),
        }
    }
}

#[interface(name = "org.clipboard.Manager")]
impl Manager {
    async fn get_history(&self) -> Vec<(String, String, String)> {
        let storage = self.storage.clone();
        tokio::task::spawn_blocking(move || {
            let mut s = storage.lock().unwrap();
            s.load();
            s.entries
                .iter()
                .map(|e| (e.kind.clone(), e.content.clone(), e.timestamp.clone()))
                .collect::<Vec<_>>()
        })
        .await
        .unwrap_or_default()
    }

    async fn set_selection(
        &self,
        index: i32,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) {
        // The storage call spins on a flock for up to 2 s and reads/writes
        // history.json. Keep it off the async worker.
        let storage = self.storage.clone();
        let outcome = tokio::task::spawn_blocking(move || {
            let mut s = storage.lock().unwrap();
            s.take_and_bump(index)
        })
        .await;

        let entry = match outcome {
            Ok(Ok(Some(e))) => Some(e),
            Ok(Ok(None)) => {
                eprintln!("SetSelection: invalid index {index}");
                None
            }
            Ok(Err(e)) => {
                eprintln!("SetSelection: storage error: {e:#}");
                None
            }
            Err(e) => {
                eprintln!("SetSelection: blocking task panicked: {e}");
                None
            }
        };

        if let Some(entry) = entry {
            HistoryStorage::mark_ignore_window(1500);

            let kind = entry.kind.clone();
            let content = entry.content.clone();
            let copy_result = tokio::task::spawn_blocking(move || -> Result<()> {
                match kind.as_str() {
                    "text" => {
                        wl::copy_text(ClipboardType::Regular, &content)?;
                        wl::copy_text(ClipboardType::Primary, &content)?;
                    }
                    "image" => {
                        let img = image::open(&content)
                            .with_context(|| format!("failed to open image {content}"))?;
                        let mut buf = Vec::new();
                        img.write_to(
                            &mut std::io::Cursor::new(&mut buf),
                            image::ImageFormat::Png,
                        )
                        .context("failed to encode image as PNG")?;
                        wl::copy(ClipboardType::Regular, "image/png", buf.clone())?;
                        wl::copy(ClipboardType::Primary, "image/png", buf)?;
                    }
                    other => {
                        eprintln!("SetSelection: unknown entry kind {other:?}");
                    }
                }
                Ok(())
            })
            .await;

            match copy_result {
                Ok(Ok(())) => {}
                Ok(Err(e)) => eprintln!("SetSelection: copy failed: {e:#}"),
                Err(e) => eprintln!("SetSelection: copy task panicked: {e}"),
            }
        }

        // Emit unconditionally. Even a bad index or a lock timeout means the
        // client's view may be stale; it re-syncs on this signal.
        let _ = Self::history_changed(&emitter).await;
    }

    async fn delete_entry(
        &self,
        index: i32,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) {
        let storage = self.storage.clone();
        let outcome = tokio::task::spawn_blocking(move || {
            let mut s = storage.lock().unwrap();
            s.remove_entry(index)
        })
        .await;

        match outcome {
            Ok(Ok(())) => {}
            Ok(Err(e)) => eprintln!("DeleteEntry: storage error: {e:#}"),
            Err(e) => eprintln!("DeleteEntry: blocking task panicked: {e}"),
        }

        let _ = Self::history_changed(&emitter).await;
    }

    async fn ignore_next(&self) {
        HistoryStorage::mark_ignore_window(1500);
    }

    async fn show(
        &self,
        x: i32,
        y: i32,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) {
        eprintln!("Show() invoked with {x} {y}");
        let _ = Self::show_requested(&emitter, x, y).await;
    }

    // ---- Signals --------------------------------------------------------
    #[zbus(signal)]
    async fn history_changed(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn show_requested(
        emitter: &SignalEmitter<'_>,
        x: i32,
        y: i32,
    ) -> zbus::Result<()>;
}

/// Entry point for the long-running D-Bus server.
pub async fn run() -> Result<()> {
    let manager = Manager::new();

    let conn = zbus::connection::Builder::session()?
        .name("org.clipboard.Manager")?
        .serve_at("/", manager)?
        .build()
        .await?;

    // In-process clipboard watcher replaces the old `wl-paste --watch` subprocess.
    crate::watcher::spawn_watcher();

    // Watch the history file for external writes.
    tokio::spawn(watch_history_file(conn.clone()));

    eprintln!("clipboard-server running (D-Bus: org.clipboard.Manager)");
    std::future::pending::<()>().await;
    Ok(())
}

async fn watch_history_file(conn: Connection) {
    use notify::{Event, RecursiveMode, Watcher};

    let history = HistoryStorage::history_path();
    let Some(dir) = history.parent().map(|p| p.to_path_buf()) else {
        return;
    };
    let _ = std::fs::create_dir_all(&dir);

    let (tx, mut rx) = tokio::sync::mpsc::channel::<()>(4);

    let mut watcher = match notify::recommended_watcher(
        move |res: notify::Result<Event>| {
            use notify::EventKind;
            let Ok(event) = res else { return };
            match event.kind {
                EventKind::Modify(_) | EventKind::Create(_) | EventKind::Remove(_) => {}
                _ => return,
            }
            let _ = tx.try_send(());
        },
    ) {
        Ok(w) => w,
        Err(e) => {
            eprintln!("notify watcher failed: {e}");
            return;
        }
    };

    if watcher.watch(&dir, RecursiveMode::NonRecursive).is_err() {
        return;
    }
    let _keep = watcher;

    while rx.recv().await.is_some() {
        // Debounce: coalesce bursts of FS events into one signal.
        tokio::time::sleep(Duration::from_millis(200)).await;
        while rx.try_recv().is_ok() {}

        let _ = conn
            .emit_signal(
                None::<&str>,
                "/",
                "org.clipboard.Manager",
                "HistoryChanged",
                &(),
            )
            .await;
    }
}
