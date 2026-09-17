"""Load the Stylix base16 palette and turn it into a rofi theme string."""
import json
from pathlib import Path

from .config import FALLBACK_THEME, STYLIX_PALETTE_PATH


def _hex(color: dict) -> str:
    return f"#{color['r']:02x}{color['g']:02x}{color['b']:02x}"


def load_theme(path: Path = STYLIX_PALETTE_PATH) -> str:
    try:
        with path.open("r", encoding="utf-8") as f:
            palette = json.load(f)
        bg = _hex(palette["base00"])
        fg = _hex(palette["base05"])
        textcol = _hex(palette["base05"])
        button = _hex(palette["base0D"])
    except (FileNotFoundError, json.JSONDecodeError, KeyError, TypeError):
        return FALLBACK_THEME
    return f"* {{ textcol: {textcol}; bg: {bg}; button: {button}; fg: {fg}; }}"
