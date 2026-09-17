import os
import subprocess
from dataclasses import dataclass


@dataclass
class RofiResult:
    returncode: int
    stdout: str
    stderr: str

    @property
    def lines(self) -> list[str]:
        if not self.stdout:
            return []
        return [l for l in self.stdout.rstrip("\n").split("\n") if l]


def select(
    items: list[str],
    *,
    prompt: str = "",
    mesg: str = "",
    multi: bool = False,
    theme: str = "",
    keybindings: dict[int, str] | None = None,
    no_custom: bool = False,
) -> RofiResult:
    args = ["rofi", "-dmenu", "-scroll-method", "1"]

    # Base theme file, if provided by the wrapper (or the user's environment).
    theme_file = os.environ.get("BOARD_LIST_RASI", "")
    if theme_file:
        args += ["-theme", theme_file]

    if multi:
        args += [
            "-multi-select",
            "-ballot-unselected-str", "",
            "-ballot-selected-str", "➤ ",
        ]
    if no_custom:
        args.append("-no-custom")
    if prompt:
        args += ["-p", prompt]
    if mesg:
        args += ["-mesg", mesg]
    if theme:
        args += ["-theme-str", theme]
    if keybindings:
        args += ["-kb-accept-custom", ""]
        for number, kb in keybindings.items():
            args += [f"-kb-custom-{number}", kb]

    input_text = "\n".join(items)
    if items:
        input_text += "\n"

    proc = subprocess.run(
        args,
        input=input_text,
        capture_output=True,
        text=True,
    )
    return RofiResult(proc.returncode, proc.stdout, proc.stderr)
