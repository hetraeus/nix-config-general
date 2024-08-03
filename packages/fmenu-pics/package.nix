{ perSystem = { pkgs, ... }: {
  packages.fmenu-pics = pkgs.writeShellApplication {
    name          = "fmenu-pics";
    runtimeInputs = [ pkgs.fzf pkgs.imagemagick pkgs.waifu2x-converter-cpp pkgs.wl-clipboard-rs ];
    #-> ImgUR
    #convert to
    # qr send
    # kdeconnect
    # croc
    #  --color='bg+:#04727d,fg+:#fac6c1,hl+:#ff497c,gutter:-1'
    text = ''
      export  FZF_DEFAULT_OPTS="\
        --layout=reverse        \
        --info=hidden           \
        --scroll-off=5          \
        --no-separator          \
        --gutter=' '            \
        --prompt='  '           \
        --pointer=' '           \
      "
      fm_img_imgur()    { for each_image in "$@"; do
        ~/.local/bin/pull_update/imgur.sh/imgur.sh "$each_image" 1>>"$HOME"/.cache/shell/imgur_uploads 2>> "$HOME"/.cache/shell/imgur_uploads
        tail --lines=2 ~/.cache/shell/imgur_uploads | wl-copy
        done }
      fm_img_shrink()   { for each_file in "$@"; do
        imgp   --optimize      --                      "$each_file" # use imagemagick
        done }
      fm_img_wipe_meta(){ for each_file in "$@"; do
        magick -- "$each_file" -strip  "$each_file"
        done }
      fm_upscale_2x()   { for each_file in "$@"; do
        waifu2x-ncnn-vulkan    -i "$each_file"     -o "''${each_file%.*}x2.''${each_file##*.}"  -s 2
        done }
      fm_upscale_2eg()  { for each_file in "$@"; do
        realesrgan-ncnn-vulkan -i "$each_file"     -o "''${each_file%.*}xEG.''${each_file##*.}" -s 2
        done }
      fm_upscale_4x()   { for each_file in "$@"; do
        waifu2x-ncnn-vulkan    -i "$each_file"     -o "''${each_file%.*}x4.''${each_file##*.}"  -s 4
        done }
      while ! "''${finished:-false}"; do
      operation="$(fzf   \
        --color='fg:#bbbbbb' \
        --header="$0
      ''${*##*/}" <<< \
      "💫 quick edit
      🔳 copy image
      👣 copy path
      💬 copy image text
      🔃 rotate
      🔄 rotate
      ェ mirror
      H  mirror
      😺 upscale 2x
      😺 upscale 2xEsrgan
      😸 upscale 4x
      🪄 gmic
      🐶 Gimp
      🎨 Krita
      🎩 convert format
      📜 print
      🔬 search by image
      📎 send (generic)
      💌 send (image)
      Æ▫ steg
      😎 filter
      🔸 shrink
      🧹 wipe metadata
      ✅ Done")"
      case "''${operation:-"✅ Done"}" in
        *" quick edit"      )   satty                                                "$*" ;;
        *" Gimp"            )   gimp                                          --     "$*" ;;
        *" gmic"            )   gmic_qt                                              "$*" ;;
        *" Krita"           )   krita                                         --     "$*" ;;
        *" copy image"      )   wl-copy --type image/png -                    --   < "$*" ;;
        *" copy path"       )   wl-copy --primary <<< "$*";              wl-copy <<< "$*" ;;
        # *" copy image text" )   ocr_pic                                              "$*" ;;
        "🔃 rotate"         )   for i in "$@"; do magick "$i" -rotate  90 "$i";  done ;;
        "🔄 rotate"         )   for i in "$@"; do magick "$i" -rotate 270 "$i";  done ;;
        "ェ mirror"         )   magick mogrify -flop                                     "$*" ;;
        "H  mirror"         )   magick mogrify -flip                                     "$*" ;;
        *" convert format"  )   ~/.local/bin/scripts/fmenu-pics-convert              "$*" ;;
        *" print"           )   ~/.local/bin/scripts/fmenu-quickprint                "$*" ;;
        *" filter"          )   ~/.local/bin/scripts/fmenu-pics-filter               "$*" ;;
        *" search by image" )   web_image_search                                     "$*" ;;
        *" wipe metadata"   )   fm_img_wipe_meta                                     "$*" ;;
        *" shrink"          )   fm_img_shrink                                        "$*" ;;
        *" send (generic)"  )   ~/.local/bin/scripts/fmenu-send-regular              "$*" ;;
        *" send (image)"    )   fm_img_imgur                                         "$@" ;;
        *" upscale 2x"      )   fm_upscale_2x                                        "$@" ;;
        *" upscale 2xEsrgan")   fm_upscale_2eg                                       "$@" ;;
        *" upscale 4x"      )   fm_upscale_4x                                        "$@" ;;
        *" Done"            )   finished=true                                             ;;
      esac; done
    '';
  };
};}
