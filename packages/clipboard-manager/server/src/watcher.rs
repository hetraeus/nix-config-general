use crate::storage::HistoryStorage;
use image::DynamicImage;
use std::io::Read;
use wl_clipboard_rs::{
    paste::Seat,
    watch::{ClipboardEvent, ClipboardType, Offer, Watcher},
};

/// Spawn two blocking OS threads watching the regular and primary clipboards.
pub fn spawn_watcher() {
    for clipboard in [ClipboardType::Regular, ClipboardType::Primary] {
        std::thread::spawn(move || loop {
            if let Err(e) = watch_one(clipboard) {
                eprintln!("watcher ({clipboard:?}) error: {e:#}, restarting in 500ms");
                std::thread::sleep(std::time::Duration::from_millis(500));
            }
        });
    }
}

fn watch_one(clipboard: ClipboardType) -> anyhow::Result<()> {
    let mut watcher = Watcher::new(clipboard, Seat::Unspecified)?;

    while let Some(event) = watcher.next_event()? {
        match event {
            ClipboardEvent::Changed {
                mime_types,
                offer,
                ..
            } => {
                if let Err(e) = handle_changed(&mime_types, offer) {
                    eprintln!("failed to handle clipboard offer: {e:#}");
                }
            }
            ClipboardEvent::Cleared { .. } => {}
        }
    }
    Ok(())
}

fn handle_changed(mime_types: &[String], mut offer: Offer<'_>) -> anyhow::Result<()> {
    if HistoryStorage::should_ignore_now() {
        return Ok(());
    }

    // ---- Password-manager hint ------------------------------------------
    if mime_types
        .iter()
        .any(|t| t.contains("x-kde-passwordManagerHint"))
    {
        eprintln!("Skipping (password-manager hint)");
        return Ok(());
    }

    // ---- Image branch ---------------------------------------------------
    if let Some(image_mime) = mime_types.iter().find(|t| t.starts_with("image/")) {
        let mut reader = offer.receive(image_mime)?;
        let mut data = Vec::new();
        reader.read_to_end(&mut data)?;
        if data.is_empty() {
            return Ok(());
        }

        let Some(img) = load_image(&data, image_mime) else {
            eprintln!("Failed to decode image (mime={image_mime})");
            return Ok(());
        };

        // One lock, one load, one save. Previously this constructed two
        // `HistoryStorage`s and read history.json twice per paste; if the
        // second lock attempt timed out, the image was written to disk but
        // never recorded.
        let mut storage = HistoryStorage::empty();
        storage.add_image_entry(&img, image_mime)?;
        return Ok(());
    }

    // ---- Text branch ----------------------------------------------------
    // Prefer the charset-qualified type: some GUI apps (Firefox,
    // Thunderbird, Nemo) put escaped sequences like `\U0001f342` in bare
    // "text/plain" but the real UTF-8 character in
    // "text/plain;charset=utf-8". Terminals typically put the raw bytes in
    // both, so preferring the qualified type is harmless for them.
    let text_mime = if mime_types
        .iter()
        .any(|t| t.eq_ignore_ascii_case("text/plain;charset=utf-8"))
    {
        "text/plain;charset=utf-8"
    } else if mime_types.iter().any(|t| t == "text/plain") {
        "text/plain"
    } else {
        return Ok(());
    };

    let mut reader = offer.receive(text_mime)?;
    let mut data = Vec::new();
    reader.read_to_end(&mut data)?;
    if data.is_empty() {
        return Ok(());
    }

    let mut text = String::from_utf8_lossy(&data).into_owned();
    if text.ends_with("\r\n") {
        text.truncate(text.len() - 2);
    } else if text.ends_with('\n') || text.ends_with('\r') {
        text.truncate(text.len() - 1);
    }

    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Ok(());
    }
    let mut it = trimmed.chars();
    if let Some(c) = it.next() {
        if it.next().is_none()
            && c.is_ascii()
            && (c.is_ascii_alphanumeric() || c.is_ascii_punctuation())
        {
            return Ok(());
        }
    }

    let mut storage = HistoryStorage::empty();
    storage.add_entry("text", &text, "")?;

    Ok(())
}

fn load_image(data: &[u8], mime: &str) -> Option<DynamicImage> {
    if let Ok(img) = image::load_from_memory(data) {
        return Some(img);
    }
    if mime == "image/svg+xml" {
        return render_svg(data);
    }
    None
}

fn render_svg(data: &[u8]) -> Option<DynamicImage> {
    let opt = resvg::usvg::Options::default();
    let tree = resvg::usvg::Tree::from_data(data, &opt).ok()?;
    let size = tree.size().to_int_size();
    let (w, h) = {
        let (w, h) = (size.width(), size.height());
        if w == 0 || h == 0 {
            (256, 256)
        } else {
            (w, h)
        }
    };
    let mut pixmap = resvg::tiny_skia::Pixmap::new(w, h)?;
    let mut pm = pixmap.as_mut();
    resvg::render(&tree, resvg::tiny_skia::Transform::default(), &mut pm);
    let png = pixmap.encode_png().ok()?;
    image::load_from_memory(&png).ok()
}
