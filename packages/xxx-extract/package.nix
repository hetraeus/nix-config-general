{ perSystem = { pkgs, ... }: {
  packages.xxx = pkgs.writeShellApplication {
    name               = "xxx";
    excludeShellChecks = [ "SC2001" ];
    runtimeInputs      = [ pkgs.coreutils pkgs.libarchive pkgs.gnused ]; # xz bzip2 lzo gzip
    text = ''
      for compressed_file in "$@"; do
        exts=(
          # --- Common compression formats ---
          gz gzip
          bz2 bzip2
          bz3
          xz
          lz lzma lzo lz4
          z
          zst zstd
          # --- Combined / common compound extensions ---
          tgz taz
          tbz tbz2
          tlz
          txz
          tzst
          # --- Popular archive containers ---
          zip
          7z
          rar
          ace
          cab
          arj
          # --- Disk / image-like containers ---
          iso
          img
          dmg
          # --- Package / distribution formats ---
          deb
          rpm
          pkg
          # --- Java / ecosystem ---
          jar war ear
          # --- Android / Apple ---
          apk
          ipa
          # --- Microsoft / Office (ZIP-based) ---
          docx docm
          xlsx xlsm
          pptx pptm
          # --- OpenDocument (ZIP-based) ---
          odt ods odp
          odg odf odi odm
          ott ots otp otg
          # --- Other ZIP-based / containers ---
          epub
          xpi
          crx
          vsix
          whl
          nupkg
          appx msix
          kmz
          3mf
          usdz
          aar
          # --- Game / media archives ---
          wad
          pak
          dat
          # --- Comic / ebook variants ---
          cbz
          cbr
          # --- Misc / less common ---
          lha lzh
          zoo
        )
        prefix_exts=(cpio pax tar iso)
        regex="$(IFS='|'; echo "''${exts[*]}")"
        prefix_regex="$(IFS='|'; echo "''${prefix_exts[*]}")"
        EXTRACTION_DIR="$(sed --regexp-extended "s/(\.($prefix_regex))?\.(($regex))$//I" <<< "$compressed_file")"
        mkdir "$EXTRACTION_DIR" || true
        bsdtar --extract --verbose \
        --file="$compressed_file"  \
        --directory="$EXTRACTION_DIR"
        done
    '';
  };
};}
