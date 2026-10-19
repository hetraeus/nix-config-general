use crate::app::{Message, State};
use iced::widget::{button, column, container, row, text, Space};
use iced::{Alignment, Element, Length};

pub fn overlay<'a>(
    state: &'a State,
    background: Element<'a, Message>,
) -> Element<'a, Message> {
    let theme = &state.theme;

    let dialog = container(
        column![
            text("Delete this entry from history?")
                .font(theme.font)
                .color(theme.fg)
                .size(13)
                .width(Length::Fill)
                .align_x(Alignment::Center),
            Space::new().height(Length::Fixed(12.0)),
            row![
                button(text("Cancel").font(theme.font).color(theme.fg).size(12))
                    .on_press(Message::CancelDelete)
                    .width(Length::Fill)
                    .padding(6)
                    .style(move |_t, _s| button::Style {
                        background: Some(iced::Color::TRANSPARENT.into()),
                        border: iced::Border {
                            color: theme.comment,
                            width: 1.0,
                            radius: 4.0.into(),
                        },
                        text_color: theme.fg,
                        ..Default::default()
                    }),
                button(text("Delete").font(theme.font).color(theme.fg).size(12))
                    .on_press(Message::ConfirmDelete)
                    .width(Length::Fill)
                    .padding(6)
                    .style(move |_t, _s| button::Style {
                        background: Some(iced::Color::from_rgb(0.38, 0.13, 0.13).into()),
                        border: iced::Border {
                            color: theme.comment,
                            width: 1.0,
                            radius: 4.0.into(),
                        },
                        text_color: theme.fg,
                        ..Default::default()
                    }),
            ]
            .spacing(8),
        ]
        .spacing(8)
        .padding(16),
    )
    .width(Length::Fixed(280.0))
    .height(Length::Fixed(130.0))
    .style(move |_t| container::Style {
        background: Some(theme.bg.into()),
        border: iced::Border {
            color: theme.comment,
            width: 1.0,
            radius: 8.0.into(),
        },
        ..Default::default()
    });

    iced::widget::stack![
        container(background)
            .width(Length::Fill)
            .height(Length::Fill)
            .style(|_t| container::Style {
                background: Some(iced::Color::from_rgba(0.0, 0.0, 0.0, 0.67).into()),
                ..Default::default()
            }),
        container(dialog)
            .width(Length::Fill)
            .height(Length::Fill)
            .center_x(Length::Fill)
            .center_y(Length::Fill),
    ]
    .into()
}
