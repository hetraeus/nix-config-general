use crate::dbus;
use crate::history::{self, HistoryEntry};
use crate::outputs;
use crate::theme::Theme;
use crate::ui;
use iced::widget::Space;
use iced::{Element, Subscription, Task};
use iced_exwlshell::reexport::KeyboardInteractivity;
use iced_exwlshell::to_exwlshell_message;
use std::sync::OnceLock;
use std::time::SystemTime;
use wl_clipboard_rs::copy::{ClipboardType, MimeType, Options, Source};

// ── List geometry ───────────────────────────────────────────────────────
//
// Must match `ui::entry`: each row is 64 px tall.
pub const ROW_H: f32 = 64.0;
/// How many rows fit in the popup's list viewport.
pub const ROWS_VISIBLE: usize = 7;
/// Rows of context kept above/below the highlight once scrolling kicks in.
pub const SCROLLOFF_ROWS: usize = 3;

// ── Popup geometry ──────────────────────────────────────────────────────

const POPUP_W: u32 = 400;
const POPUP_H: u32 = 500;
const EDGE_MARGIN: i32 = 8;
const OFFSCREEN: i32 = -10000;

static MAIN_WINDOW: OnceLock<iced::window::Id> = OnceLock::new();

struct PopupGeometry {
    margin: (i32, i32, i32, i32),
}

fn popup_geometry(cursor: (i32, i32), outputs: &[outputs::OutputRect]) -> PopupGeometry {
    let (cx, cy) = cursor;

    // Fall back to 1920×1080 when the probe failed. This keeps single-monitor
    // users working on compositors we don't recognize.
    let screen = outputs::containing(outputs, cx, cy).unwrap_or(outputs::OutputRect {
        x: 0,
        y: 0,
        w: 1920,
        h: 1080,
    });

    let pw = POPUP_W as i32;
    let ph = POPUP_H as i32;

    // `cx`/`cy` arrive in compositor-global coordinates. Layer-shell margins
    // are relative to *the surface's output* — assume that's the same output
    // the cursor is on, and translate into local coordinates.
    let lx = cx - screen.x;
    let ly = cy - screen.y;

    let want_x = (lx - pw / 2).clamp(EDGE_MARGIN, (screen.w - pw - EDGE_MARGIN).max(EDGE_MARGIN));
    let want_y = (ly - ph / 4).clamp(EDGE_MARGIN, (screen.h - ph - EDGE_MARGIN).max(EDGE_MARGIN));

    PopupGeometry {
        margin: (want_y, 0, 0, want_x),
    }
}
// ── Pinned entries ──────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct PinnedEntry {
    pub text: String,
    pub kind: PinnedKind,
}

#[derive(Debug, Clone, PartialEq)]
pub enum PinnedKind {
    Date,
    DateTime,
    Mail,
}

impl PinnedEntry {
    fn defaults() -> Vec<Self> {
        vec![
            PinnedEntry {
                text: "📅 Date".into(),
                kind: PinnedKind::Date,
            },
            PinnedEntry {
                text: "🕒 Date & time".into(),
                kind: PinnedKind::DateTime,
            },
            PinnedEntry {
                text: "💌 e-mail".into(),
                kind: PinnedKind::Mail,
            },
        ]
    }
}

// ── Pages ───────────────────────────────────────────────────────────────
//
// Ordered left-to-right: Pinned ← History → Snippets. Arrow keys move one
// step; at the edges they are a no-op.

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Page {
    Pinned,
    History,
    Snippets,
}

impl Page {
    fn index(self) -> usize {
        match self {
            Page::Pinned => 0,
            Page::History => 1,
            Page::Snippets => 2,
        }
    }

    fn from_index(i: usize) -> Self {
        match i {
            0 => Page::Pinned,
            2 => Page::Snippets,
            _ => Page::History,
        }
    }

    fn shift(self, delta: i32) -> Self {
        let i = (self.index() as i32 + delta).clamp(0, 2) as usize;
        Page::from_index(i)
    }

    fn next(self) -> Self {
        Page::from_index((self.index() + 1) % 3)
    }
}

// ── State ───────────────────────────────────────────────────────────────

pub struct State {
    pub theme: Theme,
    pub history: Vec<HistoryEntry>,
    pub filtered_history: Vec<usize>,
    pub pinned: Vec<PinnedEntry>,
    pub filtered_pinned: Vec<usize>,
    pub filter_text: String,
    pub page: Page,
    pub selected: usize,
    pub hovered: Option<usize>,
    /// Index of the first visible row within the active list. Updated by
    /// `apply_scrolloff` whenever `selected` or the list content changes.
    pub scroll_top: usize,
    pub cursor: (i32, i32),
    pub visible: bool,
    pub delete_target: Option<usize>,
    pub thumbnails: Vec<Option<iced::widget::image::Handle>>,
    history_mtime: Option<SystemTime>,
    outputs: Vec<outputs::OutputRect>,
}

impl State {
    pub fn new() -> Self {
        let history = history::load_history();
        let history_mtime = file_mtime(&history::history_path());
        let pinned = PinnedEntry::defaults();
        let filtered_pinned: Vec<usize> = (0..pinned.len()).collect();
        let mut s = Self {
            theme: Theme::load_stylix(),
            filtered_history: (0..history.len()).collect(),
            history,
            pinned,
            filtered_pinned,
            filter_text: String::new(),
            page: Page::History,
            selected: 0,
            hovered: None,
            scroll_top: 0,
            cursor: (0, 0),
            visible: false,
            delete_target: None,
            thumbnails: Vec::new(),
            history_mtime,
            outputs: outputs::query(),
        };
        s.sync_thumbnails();
        s
    }

    fn sync_thumbnails(&mut self) {
        self.thumbnails = self
            .history
            .iter()
            .map(|e| {
                if e.is_image() {
                    let p = history::thumb_path(&e.content);
                    if p.exists() {
                        Some(iced::widget::image::Handle::from_path(p))
                    } else {
                        None
                    }
                } else {
                    None
                }
            })
            .collect();
    }

    pub fn refresh_history(&mut self) {
        let path = history::history_path();
        let mtime = file_mtime(&path);
        if mtime.is_some() && mtime == self.history_mtime {
            return;
        }
        self.history_mtime = mtime;
        self.history = history::load_history();
        self.sync_thumbnails();
        self.apply_filter();
    }
    fn switch_page(&mut self, target: Page) {
        if self.page == target {
            return;
        }
        self.page = target;
        // Only reset the filter when there's actually something to reset.
        // An empty filter maps 1:1 to (0..len), so we can skip the whole pass
        // and just rebuild the index vectors.
        if !self.filter_text.is_empty() {
            self.filter_text.clear();
        }
        self.selected = 0;
        self.hovered = None;
        self.refilter();
    }

    pub fn apply_filter(&mut self) {
        self.refilter();
    }

    fn refilter(&mut self) {
        if self.filter_text.is_empty() {
            // Fast path: identity mapping, no lowercase, no allocations beyond
            // the Vec length itself.
            self.filtered_history.clear();
            self.filtered_history.extend(0..self.history.len());
            self.filtered_pinned.clear();
            self.filtered_pinned.extend(0..self.pinned.len());
        } else {
            let lower = self.filter_text.to_lowercase();
            self.filtered_history.clear();
            self.filtered_history.extend(
                self.history
                    .iter()
                    .enumerate()
                    .filter(|(_, e)| e.search_key.contains(&lower))
                    .map(|(i, _)| i),
            );
            self.filtered_pinned.clear();
            self.filtered_pinned.extend(
                self.pinned
                    .iter()
                    .enumerate()
                    .filter(|(_, p)| p.text.to_lowercase().contains(&lower))
                    .map(|(i, _)| i),
            );
        }
        let max = self.active_len().saturating_sub(1);
        if self.selected > max {
            self.selected = max;
        }
        self.apply_scrolloff();
    }

    /// Move `scroll_top` so `selected` stays `SCROLLOFF_ROWS` rows from the
    /// top (or is pinned to the closest edge). Called from `apply_filter`
    /// and from every selection change so that the highlight and the viewport
    /// update in the *same* `update()` — no post-render scroll operation.
    pub fn apply_scrolloff(&mut self) {
        let total = self.active_len();
        if total <= ROWS_VISIBLE {
            self.scroll_top = 0;
            return;
        }
        let target = self.selected.saturating_sub(SCROLLOFF_ROWS);
        let max_top = total - ROWS_VISIBLE;
        self.scroll_top = target.min(max_top);
    }

    fn active_len(&self) -> usize {
        match self.page {
            Page::History => self.filtered_history.len(),
            Page::Pinned => self.filtered_pinned.len(),
            Page::Snippets => 0,
        }
    }

    fn active_index(&self) -> Option<usize> {
        match self.page {
            Page::History => self.filtered_history.get(self.selected).copied(),
            Page::Pinned => self.filtered_pinned.get(self.selected).copied(),
            Page::Snippets => None,
        }
    }

    fn show(&mut self, x: i32, y: i32) {
        self.cursor = (x, y);
        self.visible = true;
        self.filter_text.clear();
        self.page = Page::History;
        self.selected = 0;
        self.hovered = None;
        self.scroll_top = 0;
        self.delete_target = None;
        self.apply_filter();
    }

    fn hide(&mut self) {
        self.visible = false;
        self.delete_target = None;
    }

    fn activate_selection(&self) -> Task<Message> {
        match self.page {
            Page::History => {
                if let Some(idx) = self.active_index() {
                    Task::perform(dbus::call_index("SetSelection", idx), |_| Message::Noop)
                } else {
                    Task::none()
                }
            }
            Page::Pinned => {
                let Some(idx) = self.active_index() else {
                    return Task::none();
                };
                let Some(p) = self.pinned.get(idx).cloned() else {
                    return Task::none();
                };
                match p.kind {
                    PinnedKind::Date => {
                        let text = chrono::Local::now().format("%Y-%m-%d").to_string();
                        Task::perform(ignore_and_copy(text), |_| Message::Noop)
                    }
                    PinnedKind::DateTime => {
                        let text = chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
                        Task::perform(ignore_and_copy(text), |_| Message::Noop)
                    }
                    PinnedKind::Mail => {
                        let path = std::env::var("XDG_RUNTIME_DIR").unwrap_or_default() + "/mail";
                        Task::perform(read_mail_and_copy(path), |_| Message::Noop)
                    }
                }
            }
            Page::Snippets => Task::none(),
        }
    }
}

fn file_mtime(path: &std::path::Path) -> Option<SystemTime> {
    std::fs::metadata(path).and_then(|m| m.modified()).ok()
}

async fn read_mail_and_copy(path: String) -> Option<String> {
    let text = tokio::fs::read_to_string(path).await.ok()?;
    if text.is_empty() {
        return None;
    }
    ignore_and_copy(text.clone()).await;
    Some(text)
}

async fn ignore_and_copy(text: String) {
    dbus::call_ignore_next().await;
    copy_text(text).await;
}

async fn copy_text(text: String) {
    tokio::task::spawn_blocking(move || {
        let bytes = text.into_bytes();
        for clipboard in [ClipboardType::Regular, ClipboardType::Primary] {
            let mut opts = Options::new();
            opts.clipboard(clipboard);
            if let Err(e) = opts.copy(Source::Bytes(bytes.clone().into()), MimeType::Text) {
                log::warn!("wl-clipboard-rs copy failed for {clipboard:?}: {e}");
            }
        }
    })
    .await
    .ok();
}

// ── Layer-shell helpers ─────────────────────────────────────────────────

fn move_surface(margin: (i32, i32, i32, i32)) -> Task<Message> {
    let Some(&id) = MAIN_WINDOW.get() else {
        return Task::none();
    };
    Task::done(Message::MarginChange { id, margin })
}

fn resize_surface(w: u32, h: u32) -> Task<Message> {
    let Some(&id) = MAIN_WINDOW.get() else {
        return Task::none();
    };
    iced::window::resize(id, iced::Size::new(w as f32, h as f32))
}

fn set_keyboard(k: KeyboardInteractivity) -> Task<Message> {
    let Some(&id) = MAIN_WINDOW.get() else {
        return Task::none();
    };
    Task::done(Message::KeyboardInteractivityChange {
        id,
        keyboard_interactivity: k,
    })
}

// ── Messages ────────────────────────────────────────────────────────────

#[to_exwlshell_message]
#[derive(Debug, Clone)]
pub enum Message {
    ShowRequested(i32, i32),
    HistoryChanged,

    FilterChanged(String),
    FocusFilter,
    TogglePage,
    SelectPrev,
    SelectNext,
    Activate,
    Hover(Option<usize>),
    ClickItem(usize),
    RequestDelete,
    ConfirmDelete,
    CancelDelete,
    Hide,

    Noop,
    Keyboard(iced::keyboard::Event),
}

// ── Application plumbing ────────────────────────────────────────────────

pub fn namespace() -> String {
    "clipboard-manager".into()
}

pub fn style(_state: &State, _theme: &iced::Theme) -> iced::theme::Style {
    iced::theme::Style {
        background_color: iced::Color::TRANSPARENT,
        text_color: iced::Color::WHITE,
    }
}

pub fn subscription(_state: &State) -> Subscription<Message> {
    Subscription::batch([
        iced::event::listen_with(|event, _status, _window| match event {
            iced::Event::Keyboard(kb) => Some(Message::Keyboard(kb)),
            _ => None,
        }),
        Subscription::run_with("dbus-signals", |_| {
            iced::stream::channel(100, |output| dbus::signal_stream(output))
        }),
    ])
}

pub fn update(state: &mut State, message: Message) -> Task<Message> {
    match message {
        Message::ShowRequested(x, y) => {
            state.show(x, y);
            let geo = popup_geometry((x, y), &state.outputs);
            Task::batch([
                resize_surface(POPUP_W, POPUP_H),
                move_surface(geo.margin),
                set_keyboard(KeyboardInteractivity::Exclusive),
            ])
        }
        Message::HistoryChanged => {
            state.refresh_history();
            Task::none()
        }
        Message::FilterChanged(text) => {
            state.filter_text = text;
            state.selected = 0;
            state.apply_filter();
            Task::none()
        }
        Message::FocusFilter => iced::widget::operation::focus("filter-input"),
        Message::TogglePage => {
            let target = state.page.next();
            state.switch_page(target);
            Task::none()
        }
        Message::SelectPrev => {
            if state.selected > 0 {
                state.selected -= 1;
            }
            state.apply_scrolloff();
            Task::none()
        }
        Message::SelectNext => {
            let max = state.active_len().saturating_sub(1);
            if state.selected < max {
                state.selected += 1;
            }
            state.apply_scrolloff();
            Task::none()
        }
        Message::Activate => {
            let t = state.activate_selection();
            let hide = update(state, Message::Hide);
            Task::batch([t, hide])
        }
        Message::Hover(idx) => {
            state.hovered = idx;
            Task::none()
        }
        Message::ClickItem(idx) => {
            state.selected = idx;
            let t = state.activate_selection();
            let hide = update(state, Message::Hide);
            Task::batch([t, hide])
        }
        Message::RequestDelete => {
            if state.page == Page::History {
                if let Some(idx) = state.active_index() {
                    state.delete_target = Some(idx);
                }
            }
            Task::none()
        }
        Message::ConfirmDelete => {
            if let Some(idx) = state.delete_target.take() {
                return Task::perform(dbus::call_index("DeleteEntry", idx), |_| Message::Noop);
            }
            Task::none()
        }
        Message::CancelDelete => {
            state.delete_target = None;
            Task::none()
        }
        Message::Hide => {
            state.hide();
            Task::batch([
                move_surface((0, 0, 0, OFFSCREEN)),
                set_keyboard(KeyboardInteractivity::OnDemand),
            ])
        }
        Message::Keyboard(event) => handle_key(state, event),
        Message::Noop => Task::none(),
        _ => Task::none(),
    }
}

fn handle_key(state: &mut State, event: iced::keyboard::Event) -> Task<Message> {
    use iced::keyboard::{key, Key};

    let iced::keyboard::Event::KeyPressed { key, modifiers, .. } = event else {
        return Task::none();
    };

    // The filter `text_input` is not rendered while the filter is empty, so
    // it has no focus and cannot receive this key. Seed it here and ask for
    // focus on the *next* update, once the widget exists in the tree.
    if state.filter_text.is_empty() {
        if let Key::Character(s) = &key {
            if !s.is_empty() && !modifiers.control() && !modifiers.command() {
                state.filter_text.push_str(s);
                state.selected = 0;
                state.apply_filter();
                return Task::done(Message::FocusFilter);
            }
        }
    }

    match key {
        Key::Named(key::Named::Escape) => {
            if state.delete_target.is_some() {
                state.delete_target = None;
                return Task::none();
            }
            update(state, Message::Hide)
        }
        Key::Named(key::Named::ArrowUp) => update(state, Message::SelectPrev),
        Key::Named(key::Named::ArrowDown) => update(state, Message::SelectNext),
        Key::Named(key::Named::ArrowLeft) => {
            let target = state.page.shift(-1);
            state.switch_page(target);
            Task::none()
        }
        Key::Named(key::Named::ArrowRight) => {
            let target = state.page.shift(1);
            state.switch_page(target);
            Task::none()
        }
        Key::Named(key::Named::Enter) => update(state, Message::Activate),
        Key::Named(key::Named::Tab) => update(state, Message::TogglePage),
        Key::Named(key::Named::Delete) if modifiers.shift() => {
            update(state, Message::RequestDelete)
        }
        _ => Task::none(),
    }
}

pub fn view(state: &State, window: iced::window::Id) -> Element<'_, Message> {
    let _ = MAIN_WINDOW.set(window);
    if !state.visible {
        return Space::new().into();
    }
    ui::popup(state)
}
