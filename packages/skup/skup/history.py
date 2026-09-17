"""JSON Lines history file: one JSON-encoded string per line."""
import json
from pathlib import Path
from typing import Iterable


def load(path: Path) -> list[str]:
    if not path.exists():
        return []
    entries: list[str] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(value, str):
                entries.append(value)
    return entries


def save(path: Path, entries: Iterable[str]) -> None:
    seen: set[str] = set()
    unique: list[str] = []
    for entry in entries:
        if not entry or entry in seen:
            continue
        seen.add(entry)
        unique.append(entry)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        for entry in unique:
            f.write(json.dumps(entry, ensure_ascii=False))
            f.write("\n")
    tmp.replace(path)


def prepend(path: Path, new_entries: Iterable[str]) -> None:
    existing = load(path)
    save(path, list(new_entries) + existing)


def migrate_plain(path: Path) -> None:
    """Convert an old plain-text history file to JSONL, in place."""
    if not path.exists():
        return
    with path.open("r", encoding="utf-8") as f:
        raw = f.read()
    if not raw:
        return
    lines = [l for l in raw.splitlines() if l]
    if not lines:
        return
    # If every line parses as a JSON string, it is already JSONL.
    for line in lines:
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            break
        if not isinstance(value, str):
            break
    else:
        return
    save(path, lines)
