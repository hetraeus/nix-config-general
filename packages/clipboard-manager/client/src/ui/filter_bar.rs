use crate::app::{Message, Page, State};
use iced::widget::{container, row, text, text_input, Space};
use iced::{Alignment, Element, Length};

pub fn view(state: &State) -> Element<'_, Message> {
    let theme = &state.theme;

    // Both branches are wrapped in a container of the *same* fixed height,
    // so the list below never shifts when the input appears or disappears.
    let input_inner: Element<'_, Message> = if state.filter_text.is_empty() {
        Space::new().into()
    } else {
        text_input("", &state.filter_text)
            .id("filter-input")
            .on_input(Message::FilterChanged)
            .font(theme.font)
            .align_x(Alignment::Center)
            .width(Length::Fill)
            .padding(4)
            .style(move |_t, _s| text_input::Style {
                background: iced::Color::TRANSPARENT.into(),
                border: iced::Border::default(),
                value: theme.fg,
                placeholder: theme.comment,
                selection: theme.sel,
                icon: theme.fg,
            })
            .into()
    };

    let input: Element<'_, Message> = container(input_inner)
        .width(Length::Fill)
        .height(Length::Fixed(30.0))
        .align_y(Alignment::Center)
        .into();

    let page_icon = match state.page {
        Page::History => "🗒",
        Page::Pinned => "📌",
        Page::Snippets => "✨",
    };

    let toggle = iced::widget::button(text(page_icon).font(theme.font).size(16))
        .on_press(Message::TogglePage)
        .padding(4)
        .style(move |_t, _s| iced::widget::button::Style {
            background: Some(iced::Color::TRANSPARENT.into()),
            text_color: theme.fg,
            border: iced::Border::default(),
            shadow: iced::Shadow::default(),
            snap: false,
        });

    row![input, toggle]
        .spacing(4)
        .align_y(Alignment::Center)
        .into()
}
