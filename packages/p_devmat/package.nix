{ perSystem = { pkgs, ... }: {
  packages.p_devmat = pkgs.writeShellApplication {
    name          = "p_devmat";
    runtimeInputs = [ pkgs.gnused pkgs.gnugrep pkgs.coreutils pkgs.fzf];
    text = ''

    DEVENV_FILE="''${1:-}"
    [[ -f "$DEVENV_FILE" ]] || { echo "No devenv.nix at $DEVENV_FILE" >&2; exit 1; }

    profiles=$(grep -oE 'profiles\.[A-Za-z0-9_-]+' "$DEVENV_FILE" \
               | sed 's/^profiles\.//' | sort -u)
    [[ -n "$profiles" ]] || { echo "No profiles in $DEVENV_FILE" >&2; exit 1; }

    selection=$(printf '%s\n' "$profiles" \
      | fzf --multi --prompt="profile(s)> " --height=40% --reverse \
            --header="TAB toggles, ENTER confirms" \
            --preview="grep -A 20 'profiles.{}.module' \"$DEVENV_FILE\" 2>/dev/null || true" \
            --preview-window=right:60%:wrap)

    [[ -z "''${selection:-}" ]] && exit 1

    # Emit one --profile flag per selected line, nothing else.
    while IFS= read -r p; do
      [[ -n "$p" ]] && printf '%s\n' "--profile" "$p"
    done <<< "$selection"
    '';
  };
};}
