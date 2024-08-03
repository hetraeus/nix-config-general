{ perSystem = { pkgs, ... }: {
  packages.fmenu-share = pkgs.writeShellApplication {
    name          = "fmenu-share";
    runtimeInputs = [ pkgs.coreutils pkgs.fzf pkgs.libarchive pkgs.croc pkgs.qrcp pkgs.blobdrop pkgs.xdg-utils ]; # which
    text = ''
      attach_to_mail(){
        ATTACHMENTS="$(for each_chosen_attachment in "$@"; do
                         printf "['file://%s']," "$(readlink --canonicalize-existing -- "$each_chosen_attachment")"
                         done)"
        BODY="Good morning/evening,
      You will find in attachments ______________
      I will contact you to discuss the matter if I haven't already.
      *DON'T OPEN THE ATTACHMENTS BEFORE MY CALL!*
      Best regards."
        gdbus call --session \
          --dest         org.freedesktop.portal.Desktop \
          --object-path /org/freedesktop/portal/desktop \
          --method org.freedesktop.portal.Email.ComposeEmail \
          "" \
          "{
          'subject': <'Attachments'>,
          'body': <'\"$(printf '%q' "$BODY")\"'>,
          'attachments': <\"''${ATTACHMENTS%,}\">}"
      }
      CHOICE="⛓  copy paths
      📲 my phone
      🐊 croc
      📂 new folder
      🖃  attach to mail
      ☔ drag n drop
      ☲ qr transfer
      ☣  antivirus
      💃 samba share
      📦 zip
      📦 7z
      📦 tar.gz
      📦 tar.xz
      📦 tar.bz2
      📦 tar.bz3
      📦 tar.lzma
      📦 tar.lzo
      📦 tar.xz
      📦 cpio.gz
      📦 cpio.xz
      📦 cpio.bz2
      📦 cpio.bz3
      📦 cpio.lzma
      📦 cpio.lzo
      📦 cpio.xz
      📦 tar
      📦 cpio"
      DONE="✅ Done"
      export  FZF_DEFAULT_OPTS="\
      --info=hidden             \
      --layout=reverse          \
      --no-separator            \
      --gutter=' '              \
      --pointer=' '             \
      --prompt='  '             \
      --scroll-off=5            \
      --color='gutter:-1,bg+:#3e8fb0,fg+:#ffffff'
      " # TODO: remove color hardcoding
      while ! "''${finished:-false}"; do
      operation="$(fzf --header="$(printf '%s\n' "$@")" <<< \
      "$CHOICE
      $DONE")"
      case "''${operation:-$DONE}" in
        "$DONE")            finished=true ;;
        *" croc")           croc send                                                                          -- "$@"  ;;
        *" copy paths")     printf '%s\n' "$@" > "$XDG_RUNTIME_DIR"/copied_paths ;; # needed to paste symlinks !
        *" my phone")       kdeconnect-cli --device "$(kdeconnect-cli --list-available --id-only)" --share        "$@"  ;;
        *" attach to mail") attach_to_mail                                                                        "$@"  ;;
        *" drag n drop")    blobdrop                                                                           -- "$@"  ;;
        *" qr transfer")    INTERF="$(echo /sys/class/net/*/phy80211 | cut --delimiter="/" --fields=5)"
                            qrcp send --interface "$INTERF" --port 35995 -- "$@";;
        *" antivirus")      vt analysis "$(vt scan file -- "$@" | grep --only-matching " [a-zA-Z0-9]*==$" | xargs)"
                            read -r ;;
        *" samba share")    for dir in "$@"; do
                              net usershare add "$(readlink --canonicalize-existing -- "$dir" \
                              | sed 's#\(.*\)/#\1_#;s#.*/##')" "$(readlink --canonicalize-existing -- "$dir")"
                              done ; read -r ;;
        *" new folder")     FILEPATH="$(readlink --canonicalize-existing -- "$1")"
                            mkdir --      "''${FILEPATH%/*}/new_$1"
                            mv    -- "$@" "''${FILEPATH%/*}/new_$1" ;;
        📦" "*            ) DIRNAME="$(dirname "$(readlink --canonicalize-existing "$1" )")"
                            bsdtar --auto-compress --create --directory "$DIRNAME" \
                             -s  "|^$DIRNAME||" \
                            --file "$DIRNAME$(printf '%(%Y-%m-%d_%H%M%S)T').''${operation#📦 }"  -- "$@"
                            read   -rp  "Press enter to continue" ;;
      esac; done
    '';
  };
};}
