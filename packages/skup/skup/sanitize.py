"""Strip non-printable characters. Preserve spaces and tabs."""


def sanitize(text: str) -> str:
    """Remove every character the user cannot see, keep ' ' and '\\t',
    then trim leading/trailing whitespace."""
    if not text:
        return ""
    filtered = "".join(c for c in text if c.isprintable() or c == "\t")
    return filtered.strip()
