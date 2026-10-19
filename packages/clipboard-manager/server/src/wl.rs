use anyhow::{Context, Result};
use wl_clipboard_rs::copy::{ClipboardType, MimeType, Options, Source};

/// Copy raw bytes to the given clipboard under the specified MIME type.
pub fn copy(clipboard: ClipboardType, mime: &str, data: Vec<u8>) -> Result<()> {
    let mut opts = Options::new();
    opts.clipboard(clipboard);
    opts.copy(
        Source::Bytes(data.into()),
        MimeType::Specific(mime.into()),
    )
    .context("wl-clipboard-rs copy")?;
    Ok(())
}

/// Copy UTF-8 text to the given clipboard.
pub fn copy_text(clipboard: ClipboardType, text: &str) -> Result<()> {
    let mut opts = Options::new();
    opts.clipboard(clipboard);
    opts.copy(
        Source::Bytes(text.as_bytes().to_vec().into()),
        MimeType::Text,
    )
    .context("wl-clipboard-rs copy_text")?;
    Ok(())
}
