use crate::app::{Message, Page, State, ROW_H, ROWS_VISIBLE};
use crate::ui::entry;
use iced::widget::{column, container, text};
use iced::{Alignment, Element, Length};

pub fn view(state: &State) -> Element<'_, Message> {
    // Snippets panel is intentionally blank for now.
    if state.page == Page::Snippets {
        return container(
            text("Empty")
                .font(state.theme.font)
                .color(state.theme.comment)
                .size(12),
        )
        .width(Length::Fill)
        .height(Length::Fixed(ROWS_VISIBLE as f32 * ROW_H))
        .align_x(Alignment::Center)
        .align_y(Alignment::Center)
        .into();
    }

    let indices = match state.page {
        Page::History => &state.filtered_history,
        Page::Pinned => &state.filtered_pinned,
        Page::Snippets => unreachable!(),
    };

    let total = indices.len();
    let start = state.scroll_top.min(total);
    let end = (start + ROWS_VISIBLE).min(total);

    let mut items: Vec<Element<Message>> = Vec::with_capacity(ROWS_VISIBLE);

    for i in start..end {
        let model_idx = indices[i];
        let is_current = i == state.selected;
        let is_hovered = state.hovered == Some(i);

        let item = match state.page {
            Page::History => {
                let Some(entry) = state.history.get(model_idx) else { continue };
                entry::history_row(state, entry, model_idx, is_current, is_hovered, i)
            }
            Page::Pinned => {
                let Some(pinned) = state.pinned.get(model_idx) else { continue };
                entry::pinned_row(state, pinned, is_current, is_hovered, i)
            }
            Page::Snippets => unreachable!(),
        };

        items.push(item);
    }

    if items.is_empty() {
        items.push(
            container(
                text("No entries")
                    .font(state.theme.font)
                    .color(state.theme.comment)
                    .size(12),
            )
            .padding(16)
            .into(),
        );
    }

    column(items)
        .spacing(0)
        .width(Length::Fill)
        .height(Length::Fixed(ROWS_VISIBLE as f32 * ROW_H))
        .into()
}
