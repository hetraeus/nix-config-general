mod delete_dialog;
mod entry;
mod filter_bar;
mod list;

use crate::app::{Message, State};
use iced::widget::{column, container, Space};
use iced::{Element, Length};

pub fn popup(state: &State) -> Element<'_, Message> {
    let theme = &state.theme;
    let filter = filter_bar::view(state);
    let list = list::view(state);

    let content = column![filter, Space::new().height(Length::Fixed(4.0)), list]
        .spacing(4)
        .padding(8);

    let boxed = container(content)
        .width(Length::Fixed(400.0))
        .height(Length::Fixed(500.0))
        .style(move |_t| container::Style {
            background: Some(theme.bg.into()),
            border: iced::Border {
                color: theme.comment,
                width: 1.0,
                radius: 8.0.into(),
            },
            ..Default::default()
        });

    if state.delete_target.is_some() {
        delete_dialog::overlay(state, boxed.into()).into()
    } else {
        boxed.into()
    }
}
