use crate::app::{Message, PinnedEntry, State};
use crate::history::HistoryEntry;
use iced::widget::{container, image, mouse_area, row, text, Space};
use iced::{Alignment, ContentFit, Element, Length};

pub fn history_row<'a>(
    state: &'a State,
    entry: &'a HistoryEntry,
    model_idx: usize,
    is_current: bool,
    is_hovered: bool,
    visible_idx: usize,
) -> Element<'a, Message> {
    let theme = &state.theme;

    let bg = if is_current {
        theme.sel
    } else if is_hovered {
        theme.hover
    } else {
        iced::Color::TRANSPARENT
    };

    let fg = if is_current { theme.bg } else { theme.fg };

    let inner: Element<Message> = if entry.is_image() {
        let thumb = state.thumbnails.get(model_idx).and_then(|t| t.as_ref());

        let img: Element<Message> = if let Some(handle) = thumb {
            image(handle.clone())
                .width(56.0)
                .height(56.0)
                .content_fit(ContentFit::Cover)
                .into()
        } else {
            Space::new().width(56.0).height(56.0).into()
        };

        row![
            img,
            text("🖼️ Image")
                .font(theme.font)
                .color(fg)
                .size(theme.font_size)
                .width(Length::Fill),
        ]
        .spacing(8)
        .align_y(Alignment::Center)
        .into()
    } else {
        let preview = entry
            .content
            .lines()
            .next()
            .unwrap_or("")
            .chars()
            .take(80)
            .collect::<String>();

        let line_count = entry.content.lines().count();

        let label: Element<Message> = if line_count > 1 {
            text(format!("{line_count} lines"))
                .font(theme.font)
                .color(theme.comment)
                .size(10.0)
                .into()
        } else {
            Space::new().into()
        };

        // Base layer: fills the row so the stack has the full 64 px height.
        let base = Space::new().width(Length::Fill).height(Length::Fill);

        // Preview sits at the top-left.
        let preview_layer = container(
            text(preview)
                .font(theme.font)
                .color(fg)
                .size(theme.font_size)
                .width(Length::Fill),
        )
        .width(Length::Fill)
        .height(Length::Fill)
        .align_x(iced::alignment::Horizontal::Left)
        .align_y(iced::alignment::Vertical::Top);

        // Label sits at the bottom-right of the same 64 px box.
        let label_layer = container(label)
            .width(Length::Fill)
            .height(Length::Fill)
            .align_x(iced::alignment::Horizontal::Right)
            .align_y(iced::alignment::Vertical::Bottom)
            .padding(2);

        iced::widget::stack![base, preview_layer, label_layer]
            .width(Length::Fill)
            .height(Length::Fill)
            .into()
    };

    mouse_area(
        container(inner)
            .width(Length::Fill)
            .height(Length::Fixed(64.0))
            .padding(4)
            .style(move |_t| container::Style {
                background: Some(bg.into()),
                border: iced::Border {
                    radius: 4.0.into(),
                    ..Default::default()
                },
                ..Default::default()
            }),
    )
    .on_press(Message::ClickItem(visible_idx))
    .on_enter(Message::Hover(Some(visible_idx)))
    .on_exit(Message::Hover(None))
    .into()
}

pub fn pinned_row<'a>(
    state: &'a State,
    pinned: &'a PinnedEntry,
    is_current: bool,
    is_hovered: bool,
    visible_idx: usize,
) -> Element<'a, Message> {
    let theme = &state.theme;

    let bg = if is_current {
        theme.sel
    } else if is_hovered {
        theme.hover
    } else {
        iced::Color::TRANSPARENT
    };
    let fg = if is_current { theme.bg } else { theme.fg };

    mouse_area(
        container(
            text(&pinned.text)
                .font(theme.font)
                .color(fg)
                .size(theme.font_size)
                .width(Length::Fill),
        )
        .width(Length::Fill)
        .height(Length::Fixed(64.0))
        .padding(4)
        .style(move |_t| container::Style {
            background: Some(bg.into()),
            border: iced::Border {
                radius: 4.0.into(),
                ..Default::default()
            },
            ..Default::default()
        }),
    )
    .on_press(Message::ClickItem(visible_idx))
    .on_enter(Message::Hover(Some(visible_idx)))
    .on_exit(Message::Hover(None))
    .into()
}
