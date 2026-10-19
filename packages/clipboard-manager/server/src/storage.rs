use crate::entry::HistoryEntry;
use anyhow::{bail, Context, Result};
use fs2::FileExt;
use image::DynamicImage;
use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use uuid::Uuid;

pub const MAX_ENTRIES: usize = 100;
pub const MAX_IMAGES: usize = 10;

pub struct FileLock {
    _file: File,
}
impl Drop for FileLock {
    fn drop(&mut self) {
        let _ = self._file.unlock();
    }
}

pub struct HistoryStorage {
    pub entries: Vec<HistoryEntry>,
    pub load_failed: bool,
    pub dropped_on_load: bool,
}

impl HistoryStorage {
    /// Empty in-memory storage. Directories are created so a follow-up
    /// `add_entry` / `add_image_entry` / `save` can write. The file lock
    /// is not taken and `history.json` is not read.
    ///
    /// Use this from call sites that immediately invoke a method which
    /// acquires the lock itself, to avoid a redundant lock+load round-trip.
    pub fn empty() -> Self {
        Self::ensure_dirs();
        Self {
            entries: Vec::new(),
            load_failed: false,
            dropped_on_load: false,
        }
    }

    pub fn new() -> Self {
        Self::ensure_dirs();

        let mut s = Self {
            entries: Vec::new(),
            load_failed: false,
            dropped_on_load: false,
        };

        match Self::acquire_lock(Duration::from_millis(2000)) {
            Ok(_guard) => {
                s.load();
                if s.dropped_on_load && !s.load_failed {
                    let _ = s.save();
                }
            }
            Err(_) => {
                s.load();
            }
        }
        s
    }

    fn ensure_dirs() {
        let mut dirs = vec![Self::cache_dir(), Self::thumb_dir()];
        if let Some(p) = Self::history_path().parent() {
            dirs.push(p.to_path_buf());
        }
        if let Some(p) = Self::lock_path().parent() {
            dirs.push(p.to_path_buf());
        }
        for d in dirs {
            let _ = fs::create_dir_all(d);
        }
    }

    pub fn history_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_default()
            .join(".cache/clipboard-manager/history.json")
    }

    pub fn cache_dir() -> PathBuf {
        runtime_dir().join("clipboard-manager/images")
    }

    pub fn thumb_dir() -> PathBuf {
        runtime_dir().join("clipboard-manager/thumbnails")
    }

    pub fn ignore_marker_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_default()
            .join(".cache/clipboard-manager/.ignore-until")
    }

    pub fn lock_path() -> PathBuf {
        dirs::home_dir()
            .unwrap_or_default()
            .join(".cache/clipboard-manager/.history.lock")
    }

    pub fn acquire_lock(timeout: Duration) -> Result<FileLock> {
        let path = Self::lock_path();
        if let Some(p) = path.parent() {
            let _ = fs::create_dir_all(p);
        }
        let file = OpenOptions::new()
            .create(true)
            .read(true)
            .write(true)
            .open(&path)?;
        let start = Instant::now();
        loop {
            match file.try_lock_exclusive() {
                Ok(()) => return Ok(FileLock { _file: file }),
                Err(_) if start.elapsed() < timeout => {
                    std::thread::sleep(Duration::from_millis(50));
                }
                Err(e) => bail!("lock acquisition failed: {e}"),
            }
        }
    }

    pub fn load(&mut self) {
        let path = Self::history_path();
        let data = match fs::read(&path) {
            Ok(d) if !d.is_empty() => d,
            _ => {
                self.load_failed = false;
                self.entries.clear();
                return;
            }
        };

        let root: serde_json::Value = match serde_json::from_slice(&data) {
            Ok(v) => v,
            Err(e) => {
                eprintln!(
                    "history.json exists but failed to parse ({e}) — leaving it untouched"
                );
                self.load_failed = true;
                return;
            }
        };

        self.load_failed = false;
        self.dropped_on_load = false;
        self.entries.clear();

        if let Some(arr) = root.get("entries").and_then(|v| v.as_array()) {
            for item in arr {
                let e: HistoryEntry = match serde_json::from_value(item.clone()) {
                    Ok(e) => e,
                    Err(_) => continue,
                };
                if e.kind == "image" && !Path::new(&e.content).exists() {
                    self.dropped_on_load = true;
                    continue;
                }
                self.entries.push(e);
            }
        }
    }

    pub fn save(&self) -> Result<()> {
        if self.load_failed {
            bail!("refusing to save: history.json is corrupt");
        }

        let root = serde_json::json!({ "entries": self.entries });
        let final_path = Self::history_path();
        let tmp_path = final_path.with_extension("json.tmp");

        let bytes = serde_json::to_vec(&root)?;
        {
            let mut f = File::create(&tmp_path)?;
            f.write_all(&bytes)?;
        }

        fs::rename(&tmp_path, &final_path)
            .context("failed to atomically replace history.json")?;
        Ok(())
    }

    /// Insert a text (or otherwise non-image) entry. Acquires the lock,
    /// re-reads `history.json`, deduplicates by exact content, writes the
    /// pruned+updated list back, and releases.
    pub fn add_entry(&mut self, kind: &str, content: &str, mime_type: &str) -> Result<()> {
        if content.trim().is_empty() {
            return Ok(());
        }

        let _guard = Self::acquire_lock(Duration::from_millis(2000))
            .context("could not acquire history lock")?;

        self.load();
        if self.load_failed {
            bail!("refusing to modify: history.json is corrupt");
        }

        // Exact-match duplicate → bump to top, refresh timestamp/mime.
        for i in 0..self.entries.len() {
            if self.entries[i].kind == kind && self.entries[i].content == content {
                let mut dup = self.entries.remove(i);
                dup.timestamp = now_iso();
                if !mime_type.is_empty() && dup.mime_type.is_empty() {
                    dup.mime_type = mime_type.to_string();
                }
                self.entries.insert(0, dup);
                self.save()?;
                return Ok(());
            }
        }

        let entry = HistoryEntry {
            kind: kind.into(),
            content: content.into(),
            timestamp: now_iso(),
            mime_type: mime_type.into(),
        };
        self.entries.insert(0, entry);
        while self.entries.len() > MAX_ENTRIES {
            self.entries.pop();
        }
        self.save()?;

        if kind == "image" {
            self.manage_image_cache();
        }
        Ok(())
    }

    /// Persist an image to disk and register it in history under a single
    /// lock acquisition. Replaces the previous two-step sequence of
    /// `save_image_entry` + `add_entry`, which locked and read
    /// `history.json` twice per paste and silently dropped the entry when
    /// the second lock attempt timed out.
    pub fn add_image_entry(&mut self, img: &DynamicImage, mime: &str) -> Result<PathBuf> {
        // Write PNG + thumbnail outside the lock. UUID-keyed filenames
        // cannot collide, so no coordination is required for the files.
        let path = self.save_image_entry(img)?;

        let _guard = match Self::acquire_lock(Duration::from_millis(2000)) {
            Ok(g) => g,
            Err(e) => {
                Self::remove_image_files(&path);
                return Err(e).context("could not acquire history lock for image entry");
            }
        };

        self.load();
        if self.load_failed {
            Self::remove_image_files(&path);
            bail!("refusing to modify: history.json is corrupt");
        }

        let entry = HistoryEntry {
            kind: "image".into(),
            content: path.to_string_lossy().into_owned(),
            timestamp: now_iso(),
            mime_type: mime.into(),
        };
        self.entries.insert(0, entry);
        while self.entries.len() > MAX_ENTRIES {
            self.entries.pop();
        }
        self.save()?;
        self.manage_image_cache();
        Ok(path)
    }

    pub fn save_image_entry(&self, img: &DynamicImage) -> Result<PathBuf> {
        let cache = Self::cache_dir();
        let thumbs = Self::thumb_dir();
        fs::create_dir_all(&cache)?;
        fs::create_dir_all(&thumbs)?;

        let name = format!("{}.png", Uuid::new_v4());
        let full = cache.join(&name);
        let thumb = thumbs.join(&name);

        img.save_with_format(&full, image::ImageFormat::Png)?;
        img.thumbnail(64, 64)
            .save_with_format(&thumb, image::ImageFormat::Png)?;

        Ok(full)
    }

    fn manage_image_cache(&self) {
        let mut paths: Vec<PathBuf> = self
            .entries
            .iter()
            .filter(|e| e.kind == "image")
            .map(|e| PathBuf::from(&e.content))
            .filter(|p| p.exists())
            .collect();
        while paths.len() > MAX_IMAGES {
            let oldest = paths.pop().unwrap();
            Self::remove_image_files(&oldest);
        }
    }

    fn remove_image_files(path: &Path) {
        let _ = fs::remove_file(path);
        if let Some(name) = path.file_name() {
            let _ = fs::remove_file(Self::thumb_dir().join(name));
        }
    }

    /// Retrieve the entry at `index`, moving it to the top of the list.
    ///
    /// - `Ok(Some(entry))` — success
    /// - `Ok(None)`        — index out of range or negative
    /// - `Err(..)`         — lock acquisition failed, or history is corrupt
    pub fn take_and_bump(&mut self, index: i32) -> Result<Option<HistoryEntry>> {
        if index < 0 {
            return Ok(None);
        }
        let idx = index as usize;

        let _guard = Self::acquire_lock(Duration::from_millis(2000))
            .context("could not acquire history lock")?;
        self.load();
        if self.load_failed {
            bail!("history.json is corrupt");
        }
        if idx >= self.entries.len() {
            return Ok(None);
        }

        let out = self.entries[idx].clone();

        if idx > 0 {
            let mut moved = self.entries.remove(idx);
            moved.timestamp = now_iso();
            self.entries.insert(0, moved);
            let _ = self.save();
        }
        Ok(Some(out))
    }

    /// Remove the entry at `index`. `Ok(())` covers both success and an
    /// out-of-range index; `Err(..)` means the lock could not be taken or
    /// history is corrupt, in which case nothing was removed.
    pub fn remove_entry(&mut self, index: i32) -> Result<()> {
        if index < 0 {
            return Ok(());
        }
        let idx = index as usize;

        let _guard = Self::acquire_lock(Duration::from_millis(2000))
            .context("could not acquire history lock")?;
        self.load();
        if self.load_failed {
            bail!("history.json is corrupt");
        }
        if idx >= self.entries.len() {
            return Ok(());
        }

        let entry = self.entries.remove(idx);
        if entry.kind == "image" && !entry.content.is_empty() {
            Self::remove_image_files(Path::new(&entry.content));
        }
        let _ = self.save();
        Ok(())
    }

    pub fn mark_ignore_window(ms: i64) {
        let path = Self::ignore_marker_path();
        if let Some(p) = path.parent() {
            let _ = fs::create_dir_all(p);
        }
        let deadline = unix_ms() + ms;
        let _ = fs::write(&path, deadline.to_string());
    }

    pub fn should_ignore_now() -> bool {
        let Ok(s) = fs::read_to_string(Self::ignore_marker_path()) else {
            return false;
        };
        let Ok(deadline) = s.trim().parse::<i64>() else {
            return false;
        };
        unix_ms() <= deadline
    }
}

fn runtime_dir() -> PathBuf {
    match std::env::var_os("XDG_RUNTIME_DIR") {
        Some(p) if !p.is_empty() => PathBuf::from(p),
        _ => std::env::temp_dir(),
    }
}

fn unix_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

fn now_iso() -> String {
    chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true)
}
