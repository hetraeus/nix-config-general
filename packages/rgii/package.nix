{ perSystem = { pkgs, ... }: {
  packages.rgii = pkgs.writeShellApplication {
    name          = "rgii";
    runtimeInputs = [
      pkgs.television
      pkgs.ripgrep pkgs.bat # needed by television tv text internally
      pkgs.helix
    ];
    text = ''
      (( $# == 0 )) && exit
      [[ "$XDG_SESSION_TYPE" == "wayland" ]] && command -v zeditor && AVAIL_EDITOR=zeditor
      CHOICE="$(
        tv text                \
        --no-status-bar        \
        --input-header=""      \
        --input-border=none    \
        --preview-border=plain \
        --results-border=none  \
        --inline --exact       \
        --input "$* "
        )"
      [[ -z "$CHOICE" ]] && exit
      echo "$CHOICE"
      "''${AVAIL_EDITOR:-hx}" "$CHOICE"
    '';
  };
};}
