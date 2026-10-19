use iced::{Color, Font};

#[derive(Debug, Clone)]
pub struct Theme {
    pub bg: Color,
    pub sel: Color,
    pub fg: Color,
    pub comment: Color,
    pub hover: Color,
    pub font: Font,
    pub font_size: f32,
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            bg: Color::from_rgb(0.10, 0.10, 0.18),   // #1a1a2e
            sel: Color::from_rgb(0.00, 0.50, 0.50),  // #008080
            fg: Color::from_rgb(0.94, 0.94, 0.94),   // #f0f0f0
            comment: Color::from_rgb(0.29, 0.29, 0.29),
            hover: Color::from_rgb(0.25, 0.25, 0.38), // #404060
            font: Font::MONOSPACE,
            font_size: 14.0,
        }
    }
}

impl Theme {
    /// Attempt to load a Stylix palette from ~/.config/stylix/palette.json.
    pub fn load_stylix() -> Self {
        let mut theme = Self::default();
        let Ok(home) = std::env::var("HOME") else { return theme };
        let path = format!("{home}/.config/stylix/palette.json");
        let Ok(data) = std::fs::read_to_string(&path) else { return theme };
        let Ok(json) = serde_json::from_str::<serde_json::Value>(&data) else { return theme };
        let palette = json.get("palette").unwrap_or(&json);
        let get = |key: &str| palette.get(key).and_then(|v| v.as_str()).map(String::from);
        if let Some(hex) = get("base00") { theme.bg = parse_hex(&hex); }
        if let Some(hex) = get("base03") { theme.comment = parse_hex(&hex); }
        if let Some(hex) = get("base05") { theme.fg = parse_hex(&hex); }
        if let Some(hex) = get("base0E") { theme.sel = parse_hex(&hex); }
        theme
    }
}

fn parse_hex(hex: &str) -> Color {
    let hex = hex.trim_start_matches('#');
    let r = u8::from_str_radix(&hex[0..2], 16).unwrap_or(0x1a);
    let g = u8::from_str_radix(&hex[2..4], 16).unwrap_or(0x1a);
    let b = u8::from_str_radix(&hex[4..6], 16).unwrap_or(0x2e);
    Color::from_rgb8(r, g, b)
}
