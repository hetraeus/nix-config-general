mod app;
mod dbus;
mod history;
mod outputs;   // ← new
mod theme;
mod ui;

use iced_exwlshell::daemon;
use iced_exwlshell::reexport::{Anchor, KeyboardInteractivity, Layer, LayerSize};
use iced_exwlshell::settings::{LayerShellSettings, Settings, StartMode};

fn main() -> Result<(), iced_exwlshell::Error> {
    env_logger::init();
    daemon(app::State::new, app::namespace, app::update, app::view)
        .style(app::style)
        .subscription(app::subscription)
        .settings(Settings {
            layer_settings: LayerShellSettings {
                exclusive_zone: 0,
                anchor: Anchor::Top | Anchor::Left,
                layer: Layer::Overlay,
                keyboard_interactivity: KeyboardInteractivity::None,
                start_mode: StartMode::Active,
                // Popup-sized surface, parked far off the left edge so it
                // captures nothing until ShowRequested moves it back.
                size: LayerSize::px(400, 500),
                margin: (0, 0, 0, -10000),
                ..Default::default()
            },
            ..Default::default()
        })
        .run()
}
