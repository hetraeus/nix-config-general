use serde_json::Value;
use std::process::Command;

#[derive(Debug, Clone, Copy)]
pub struct OutputRect {
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
}

/// Best-effort enumeration of logical output rectangles in compositor-global
/// coordinates. Empty vec means "couldn't probe"; callers fall back to a
/// hard-coded default.
pub fn query() -> Vec<OutputRect> {
    if std::env::var_os("SWAYSOCK").is_some() {
        if let Some(v) = run_json("swaymsg", &["-t", "get_outputs"]) {
            return parse_sway(&v);
        }
    }
    if std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some() {
        if let Some(v) = run_json("hyprctl", &["-j", "monitors"]) {
            return parse_hyprland(&v);
        }
    }
    if std::env::var_os("NIRI_SOCKET").is_some() {
        if let Some(v) = run_json("niri", &["msg", "--json", "outputs"]) {
            return parse_niri(&v);
        }
    }
    Vec::new()
}

/// Rect containing `(x, y)`, or `None`.
pub fn containing(rects: &[OutputRect], x: i32, y: i32) -> Option<OutputRect> {
    rects
        .iter()
        .copied()
        .find(|r| x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h)
}

fn run_json(cmd: &str, args: &[&str]) -> Option<Value> {
    let out = Command::new(cmd).args(args).output().ok()?;
    if !out.status.success() {
        return None;
    }
    serde_json::from_slice(&out.stdout).ok()
}

fn parse_sway(v: &Value) -> Vec<OutputRect> {
    let mut out = Vec::new();
    let Some(arr) = v.as_array() else { return out };
    for o in arr {
        if o.get("active").and_then(Value::as_bool) == Some(false) {
            continue;
        }
        let Some(r) = o.get("rect") else { continue };
        let (Some(x), Some(y), Some(w), Some(h)) = (
            r.get("x").and_then(Value::as_i64),
            r.get("y").and_then(Value::as_i64),
            r.get("width").and_then(Value::as_i64),
            r.get("height").and_then(Value::as_i64),
        ) else {
            continue;
        };
        out.push(OutputRect { x: x as i32, y: y as i32, w: w as i32, h: h as i32 });
    }
    out
}

fn parse_hyprland(v: &Value) -> Vec<OutputRect> {
    let mut out = Vec::new();
    let Some(arr) = v.as_array() else { return out };
    for o in arr {
        let (Some(x), Some(y), Some(w), Some(h)) = (
            o.get("x").and_then(Value::as_i64),
            o.get("y").and_then(Value::as_i64),
            o.get("width").and_then(Value::as_i64),
            o.get("height").and_then(Value::as_i64),
        ) else {
            continue;
        };
        out.push(OutputRect { x: x as i32, y: y as i32, w: w as i32, h: h as i32 });
    }
    out
}

fn parse_niri(v: &Value) -> Vec<OutputRect> {
    let mut out = Vec::new();
    let Some(obj) = v.as_object() else { return out };
    for (_name, o) in obj {
        let Some(logical) = o.get("logical") else { continue };
        let (Some(x), Some(y), Some(w), Some(h)) = (
            logical.get("x").and_then(Value::as_i64),
            logical.get("y").and_then(Value::as_i64),
            logical.get("width").and_then(Value::as_i64),
            logical.get("height").and_then(Value::as_i64),
        ) else {
            continue;
        };
        out.push(OutputRect { x: x as i32, y: y as i32, w: w as i32, h: h as i32 });
    }
    out
}
