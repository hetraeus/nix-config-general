# skup

A rofi-based search launcher. It lets you pick a query from history (or type a
new one), choose one or more search engines, and open the resulting URLs in
your browser.

## Usage

```console
skup              # ask for a query
skup clipboard    # use the primary selection as the query
```

Or run it as a module:

```console
python -m skup
```

## Keybindings

### Query prompt

| Key           | Action                                                    |
| ------------- | --------------------------------------------------------- |
| `Enter`       | Execute the search with the current selection and batch.  |
| `Shift+Enter` | Multi-select entries from history.                        |
| `Ctrl+Return` | Execute without saving the query to history.              |
| `Alt+Return`  | Add the current query to the batch and keep the prompt open. |
| `Escape`      | Cancel.                                                   |

### Engine prompt

| Key           | Action                       |
| ------------- | ---------------------------- |
| `Shift+Enter` | Select multiple engine tags. |
| `Escape`      | Cancel.                      |

## Configuration

| Path                                 | Purpose                                                                                                                            |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `~/.cache/search_history`            | Query history, stored as JSON Lines (one JSON-encoded string per line).                                                            |
| `$XDG_RUNTIME_DIR/search_engines.json` | Search engine definitions.                                                                                                        |
| `~/.config/stylix/palette.json`      | Stylix base16 palette used to build the rofi theme. Falls back to built-in defaults if missing or malformed.                       |

### Search engines

The engine file is a JSON array. Each entry has a `title`, a `uri`, a list of
`tags`, and an optional `description`.

```json
[
  {
    "description": "",
    "tags": ["math", "numbersequence", "oeis"],
    "title": "OEIS numeric sequences",
    "uri": "https://oeis.org/search?q=%s"
  },
  {
    "description": "World of mathematics and programming",
    "tags": ["games", "it", "math"],
    "title": "Project Euler",
    "uri": "https://projecteuler.net/"
  }
]
```

Placeholders in `uri`:

- `%s` — replaced with the search query.
- `%r` — replaced with a target. If any selected engine uses `%r`, a second
  prompt appears asking for a target, drawing from the same history.

Values are percent-encoded before substitution, so characters such as `#`,
`&`, `+`, `=`, `?`, and spaces are handled correctly.

### HTTP method

By default an engine is queried with GET: the launcher builds a URL with the
`%s` and `%r` placeholders and opens it. Engines that only accept POST can set
`"method": "POST"` and supply the form data in `body`:

```json
{
  "title": "Example POST search",
  "tags": ["post"],
  "method": "POST",
  "uri": "https://example.com/search",
  "body": "q=%s&lang=en",
  "content_type": "application/x-www-form-urlencoded"
}
```

When `method` is `POST`:

- `%s` and `%r` are substituted in both `uri` and `body`, percent-encoded
  exactly as in the GET path.
- The launcher performs the POST itself, follows HTTP redirects, and opens
  the final URL in the browser.
- If the server responds with `200` and does not redirect (no POST-Redirect-GET
  pattern), the launcher prints a warning and opens the form URL. The search
  results will not be shown, because they live in the response body, which the
  browser cannot reproduce from a URL.
- Cookies set by a prior `GET` on the same site are not preserved. Engines that
  require a session cookie for POST will fail; such sites usually also expose a
  GET endpoint, which is preferable.

`content_type` defaults to `application/x-www-form-urlencoded`. Other types are
passed through unmodified, but the placeholder substitution still uses
URL-encoding, so `application/json` bodies need to be constructed with care.

### Theme

If `~/.config/stylix/palette.json` is present and valid, the launcher maps
base16 colors to a rofi theme:

| Rofi role | Palette entry |
| --------- | ------------- |
| `bg`      | `base00`      |
| `fg`      | `base05`      |
| `textcol` | `base05`      |
| `button`  | `base0D`      |

If the file is missing or cannot be parsed, a built-in fallback theme is used.

## Install

```console
cd skup
pip install --user -e .
```

Then bind `skup` (and optionally `skup clipboard`) to your compositor
keybindings.

## Behaviour notes

- **Multiple queries.** Use `Shift+Enter` to select several history entries at
  once, or `Alt+Return` to add the current input to an in-memory batch. The
  batch is shown in the message pane. `Enter` executes everything in the batch.
- **Don't save.** `Ctrl+Return` runs the search without appending the query to
  history.
- **Targets.** When an engine uses `%r`, a follow-up prompt asks for a target.
  Targets are saved to history alongside queries.
- **Sanitisation.** Non-printable characters are stripped from all input;
  spaces and tabs are preserved.
