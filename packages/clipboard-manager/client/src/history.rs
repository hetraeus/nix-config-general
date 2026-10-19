use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct HistoryEntry {
    #[serde(rename = "type")]
    pub entry_type: String,
    pub content: String,
    pub timestamp: String,
    #[serde(default, rename = "mimeType")]
    pub mime_type: String,
    #[serde(skip)]
    pub search_key: String,
}

impl HistoryEntry {
    pub fn is_image(&self) -> bool {
        self.entry_type == "image"
    }

    /// Build the lowercase key used for filtering.
    pub fn rebuild_search_key(&mut self) {
        self.search_key = if self.is_image() {
            "image".to_string()
        } else {
            self.content.to_lowercase()
        };
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct HistoryFile {
    pub entries: Vec<HistoryEntry>,
}

pub fn history_path() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_default()
        .join(".cache/clipboard-manager/history.json")
}

pub fn thumb_dir() -> PathBuf {
    std::env::var("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/tmp"))
        .join("clipboard-manager/thumbnails")
}

pub fn thumb_path(content: &str) -> PathBuf {
    let filename = std::path::Path::new(content)
        .file_name()
        .unwrap_or_default();
    thumb_dir().join(filename)
}

pub fn load_history() -> Vec<HistoryEntry> {
    let path = history_path();
    let Ok(data) = std::fs::read_to_string(&path) else {
        return Vec::new();
    };
    let Ok(file) = serde_json::from_str::<HistoryFile>(&data) else {
        log::warn!("history.json exists but failed to parse");
        return Vec::new();
    };
    let mut entries = file.entries;
    // Prune stale image entries whose files are gone.
    entries.retain(|e| !e.is_image() || std::path::Path::new(&e.content).exists());
    for e in &mut entries {
        e.rebuild_search_key();
    }
    entries.truncate(100);
    entries
}
