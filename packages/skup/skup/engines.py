"""Load search engine definitions from $XDG_RUNTIME_DIR/search_engines.json."""
import json
from dataclasses import dataclass
from pathlib import Path

FORM_URLENCODED = "application/x-www-form-urlencoded"


@dataclass(frozen=True)
class Engine:
    title: str
    uri: str
    tags: tuple[str, ...]
    description: str = ""
    method: str = "GET"
    body: str = ""
    content_type: str = FORM_URLENCODED


def load(path: Path) -> list[Engine]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    result: list[Engine] = []
    for item in data:
        result.append(Engine(
            title=item.get("title", ""),
            uri=item.get("uri", ""),
            tags=tuple(item.get("tags", [])),
            description=item.get("description", ""),
            method=item.get("method", "GET").upper(),
            body=item.get("body", ""),
            content_type=item.get("content_type", FORM_URLENCODED),
        ))
    return result


def all_tags(engines: list[Engine]) -> list[str]:
    tags: set[str] = set()
    for engine in engines:
        tags.update(engine.tags)
    return sorted(tags)


def find_by_tag(engines: list[Engine], tag: str) -> list[Engine]:
    return [e for e in engines if tag in e.tags]


def needs_target(engine: Engine) -> bool:
    return "%r" in engine.uri or "%r" in engine.body
