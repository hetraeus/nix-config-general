"""Paths and constants."""
import os
from pathlib import Path

HOME = Path.home()


def _env_path(name: str, default: Path) -> Path:
    value = os.environ.get(name)
    return Path(value) if value else default


XDG_RUNTIME_DIR = _env_path("XDG_RUNTIME_DIR", Path("/tmp"))
XDG_CACHE_HOME = _env_path("XDG_CACHE_HOME", HOME / ".cache")

HISTORY_PATH = XDG_CACHE_HOME / "search_history"
ENGINES_PATH = XDG_RUNTIME_DIR / "search_engines.json"
STYLIX_PALETTE_PATH = HOME / ".config" / "stylix" / "palette.json"

FALLBACK_THEME = (
    "* { textcol: #cdd3de; bg: #2c393fe2; "
    "button: #89ddff; fg: #82aaff; }"
)

# rofi custom keybindings (exit codes 10 and 11)
KB_ADD_TO_BATCH = "Alt+Return"
KB_NO_SAVE = "Ctrl+Return"
