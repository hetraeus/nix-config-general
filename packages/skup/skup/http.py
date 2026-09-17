"""Submit POST requests and resolve the final URL after redirects.

Search forms that use POST are usually built around the POST-Redirect-GET
pattern: the server receives the form data, then issues a 302/303 to a GET
URL that carries the query in its path or query string. We follow that
redirect and open the resulting URL.

If the server does not redirect (it returns 200 with the results in the
response body), opening the POST URL in the browser would just show the
empty form again. The caller is informed so it can print a warning.
"""
import urllib.error
import urllib.request


DEFAULT_TIMEOUT = 10.0
USER_AGENT = "skup/0.1"


def resolve_post(
    url: str,
    body: str,
    content_type: str,
    timeout: float = DEFAULT_TIMEOUT,
) -> str:
    """Perform a POST and return the final URL after redirects.

    Raises ``urllib.error.URLError`` on network failure and
    ``urllib.error.HTTPError`` on a non-2xx/3xx response.
    """
    data = body.encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", content_type)
    req.add_header("User-Agent", USER_AGENT)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.geturl()
