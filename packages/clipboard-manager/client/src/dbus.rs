use futures::{SinkExt, StreamExt};
use std::sync::OnceLock;
use zbus::message::Type;
use zbus::{Connection, MatchRule, MessageStream};

pub const SERVICE: &str = "org.clipboard.Manager";
pub const PATH: &str = "/";
pub const INTERFACE: &str = "org.clipboard.Manager";

static SESSION: OnceLock<Connection> = OnceLock::new();

/// One shared session-bus connection for the whole process. First caller
/// pays the handshake; everyone else gets a cheap clone of the handle.
async fn session() -> Option<&'static Connection> {
    if let Some(c) = SESSION.get() {
        return Some(c);
    }
    match Connection::session().await {
        Ok(c) => {
            // If another task won the race, `set` returns Err with our
            // connection back. Dropping it is fine — the winner is what
            // everyone will see via `SESSION.get()`.
            let _ = SESSION.set(c);
            SESSION.get()
        }
        Err(e) => {
            log::error!("D-Bus session connection failed: {e}");
            None
        }
    }
}

/// Long-running stream of clipboard-manager signals.
pub async fn signal_stream(
    mut output: iced::futures::channel::mpsc::Sender<crate::app::Message>,
) {
    let Some(conn) = session().await else { return };

    let rule = MatchRule::builder()
        .msg_type(Type::Signal)
        .interface(INTERFACE)
        .unwrap()
        .build();

    let mut stream = match MessageStream::for_match_rule(rule, conn, None).await {
        Ok(s) => s,
        Err(e) => {
            log::error!("failed to subscribe to D-Bus signals: {e}");
            return;
        }
    };

    while let Some(Ok(msg)) = stream.next().await {
        let header = msg.header();
        let Some(member) = header.member() else { continue };
        match member.as_str() {
            "ShowRequested" => {
                if let Ok((x, y)) = msg.body().deserialize::<(i32, i32)>() {
                    let _ = output.send(crate::app::Message::ShowRequested(x, y)).await;
                }
            }
            "HistoryChanged" => {
                let _ = output.send(crate::app::Message::HistoryChanged).await;
            }
            _ => {}
        }
    }
}

/// Fire-and-forget call to a server method that takes a single int32 index
/// (`SetSelection`, `DeleteEntry`).
pub async fn call_index(method: &'static str, index: usize) {
    let Some(conn) = session().await else { return };
    if let Err(e) = conn
        .call_method(Some(SERVICE), PATH, Some(INTERFACE), method, &(index as i32,))
        .await
    {
        log::warn!("D-Bus call {method} failed: {e}");
    }
}

/// Fire-and-forget: ask the server to ignore the next clipboard change for
/// ~1.5 s. Used before we push pinned content so it doesn't land in history.
pub async fn call_ignore_next() {
    let Some(conn) = session().await else { return };
    if let Err(e) = conn
        .call_method(Some(SERVICE), PATH, Some(INTERFACE), "IgnoreNext", &())
        .await
    {
        log::warn!("D-Bus call IgnoreNext failed: {e}");
    }
}
