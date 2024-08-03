{ perSystem = { pkgs, ... }: {
  packages.fmenu-prewfont = let
    gen-font-preview = pkgs.writeShellApplication {
      name          = "gen-font-preview";
      runtimeInputs = [ pkgs.imagemagick ];
      text = ''
        EXAMPLE_01=\
        "ABCDEFGHI
        JKLMNOPQR
        STUVWXYZ
        abcdefghi
        jklmnopqr
        stuvwxyz
        1234567890
        1lI 0O 🯳3E
        😄ツ👍ξë"
        CHOSEN_TXT="$EXAMPLE_01"
        SIZE=800x800
        FONT_SIZE=50
        FG_COLOR='#000000'
        BG_COLOR='#ffffff'
        TMP_PIC="$XDG_RUNTIME_DIR/font_prev.png"
        magick convert                  \
         -size "$SIZE"   xc:"$BG_COLOR" \
         -gravity        center         \
         -pointsize     "$FONT_SIZE"    \
         -font          "$1"            \
         -fill          "$FG_COLOR"     \
         -annotate +0+0 "$CHOSEN_TXT"   \
                         PNG24:"$TMP_PIC" # keep PNG24 or few font thumbnails would break !
      '';
    };
  in pkgs.writeShellApplication {
    name               = "fmenu-prewfont";
    text               = builtins.readFile ./fmenu-prewfont;
    runtimeInputs      = [ gen-font-preview pkgs.wl-clipboard-rs pkgs.fzf pkgs.kitty pkgs.fontconfig ];
  };
};}
