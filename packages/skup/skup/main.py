"""Entry point and orchestration."""
import random
import subprocess
import sys
import time

from . import config, engines, history, http, rofi, sanitize, stylix, url

ASKME_HELP = """\
Enter                execute search
Shift+Enter          select multiple queries
Ctrl+Return          execute without saving to history
Alt+Return           add to batch, keep going"""

ENGINE_HELP = """\
Shift+Enter          select multiple engines"""


def cli(argv: list[str] | None = None) -> int:
    if argv is None:
        argv = sys.argv[1:]
    op = argv[0] if argv else "askme"
    if op not in ("askme", "clipboard"):
        print(f"usage: {sys.argv[0]} [askme|clipboard]", file=sys.stderr)
        return 2

    history.migrate_plain(config.HISTORY_PATH)

    if op == "clipboard":
        return _run_clipboard()
    return _run_askme()


def _run_clipboard() -> int:
    query = _from_clipboard()
    if not query:
        return 1
    history.prepend(config.HISTORY_PATH, [query])
    return _dispatch([query])


def _run_askme() -> int:
    queries, save = _ask_queries()
    if not queries:
        return 1
    if save:
        history.prepend(config.HISTORY_PATH, queries)
    return _dispatch(queries)


def _ask_queries() -> tuple[list[str], bool]:
    theme = stylix.load_theme()
    batch: list[str] = []
    while True:
        entries = history.load(config.HISTORY_PATH)
        mesg = ASKME_HELP
        if batch:
            mesg += "\n\nBatch (" + str(len(batch)) + "):\n"
            mesg += "\n".join("  • " + b for b in batch)
        result = rofi.select(
            entries,
            prompt=" 🜚  ",
            mesg=mesg,
            multi=True,
            theme=theme,
            keybindings={
                1: config.KB_ADD_TO_BATCH,
                2: config.KB_NO_SAVE,
            },
        )
        selected = [sanitize.sanitize(l) for l in result.lines]
        selected = [s for s in selected if s]

        if result.returncode == 1:
            return [], True
        if result.returncode == 10:
            batch.extend(selected)
            continue
        if result.returncode == 11:
            batch.extend(selected)
            return batch, False
        if result.returncode == 0:
            batch.extend(selected)
            return batch, True
        return [], True


def _ask_target() -> list[str]:
    theme = stylix.load_theme()
    entries = history.load(config.HISTORY_PATH)
    result = rofi.select(
        entries,
        prompt="Target",
        mesg=ASKME_HELP,
        multi=True,
        theme=theme,
    )
    if result.returncode != 0:
        return []
    targets = [sanitize.sanitize(l) for l in result.lines]
    targets = [t for t in targets if t]
    if targets:
        history.prepend(config.HISTORY_PATH, targets)
    return targets


def _dispatch(queries: list[str]) -> int:
    theme = stylix.load_theme()
    engine_list = engines.load(config.ENGINES_PATH)
    tags = engines.all_tags(engine_list)
    if not tags:
        print("skup: no engines configured", file=sys.stderr)
        return 1

    prompt = queries[0][:80] + ("…" if len(queries[0]) > 80 else "")
    result = rofi.select(
        tags,
        prompt=prompt,
        mesg=ENGINE_HELP,
        multi=True,
        theme=theme,
        no_custom=True,
    )
    if result.returncode != 0:
        return 2

    selected_tags = [sanitize.sanitize(l) for l in result.lines]
    valid_tags = set(tags)
    selected_tags = [t for t in selected_tags if t in valid_tags]
    if not selected_tags:
        return 2

    selected_engines: list[engines.Engine] = []
    for tag in selected_tags:
        for engine in engines.find_by_tag(engine_list, tag):
            if engine not in selected_engines:
                selected_engines.append(engine)

    if any(engines.needs_target(e) for e in selected_engines):
        targets = _ask_target()
        if not targets:
            return 1
    else:
        targets = [""]

    urls: list[str] = []
    for query in queries:
        for target in targets:
            for engine in selected_engines:
                if engines.needs_target(engine) and not target:
                    continue
                resolved = _resolve_engine(engine, query, target)
                if resolved:
                    urls.append(resolved)

    _open_urls(urls)
    return 0

def _resolve_engine(engine: engines.Engine, query: str, target: str) -> str | None:
    """Return the URL to open, or None on failure."""
    if engine.method == "POST":
        post_url = url.substitute(engine.uri, query, target)
        post_body = url.substitute(engine.body, query, target)
        try:
            final = http.resolve_post(post_url, post_body, engine.content_type)
        except Exception as exc:
            print(f"skup: POST to {post_url} failed: {exc}", file=sys.stderr)
            return None
        if final == post_url:
            print(
                f"skup: {engine.title} did not redirect after POST; "
                f"opening the form URL, results may not be shown",
                file=sys.stderr,
            )
        return final
    return url.substitute(engine.uri, query, target)

def _from_clipboard() -> str:
    try:
        proc = subprocess.run(
            ["wl-paste", "--primary", "--no-newline"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""
    return sanitize.sanitize(proc.stdout)


def _open_urls(urls: list[str]) -> None:
    for u in urls:
        subprocess.Popen(
            ["xdg-open", u],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        time.sleep(0.1 + random.random() * 0.1)
