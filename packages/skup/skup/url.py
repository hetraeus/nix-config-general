"""Substitute %s and %r in URL and form-body templates with encoded values."""
from urllib.parse import quote_plus

_Q = "\x00Q\x00"
_R = "\x00R\x00"


def substitute(template: str, query: str, target: str = "") -> str:
    """Replace %s and %r with percent-encoded values.

    The placeholders cannot collide with real input because NUL bytes are
    stripped from queries by ``sanitize``, so a query can never contain
    ``\\x00``.
    """
    if not template:
        return template
    out = template.replace("%s", _Q).replace("%r", _R)
    out = out.replace(_Q, quote_plus(query))
    out = out.replace(_R, quote_plus(target))
    return out


# Backwards-compatible alias for the GET path.
build = substitute
