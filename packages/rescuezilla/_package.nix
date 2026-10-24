{ lib
, stdenv
, fetchFromGitHub
, wrapGAppsHook3
, gobject-introspection
, makeWrapper
, python3
, gtk3
, systemd
, pkgs
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pygobject3
    pycairo
    babel
  ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rescuezilla";
  version = "2.6.2";

  src = fetchFromGitHub {
    owner = "rescuezilla";
    repo = "rescuezilla";
    rev = finalAttrs.version;
    # Upstream stores every *.png in Git LFS. Without this, the images are
    # ~130-byte text pointer files and GTK can't load them.
    fetchLFS = true;
    hash = "sha256-BA/jYJ4ltrUnsaaozryS25XsoaYjfw+nTFGEgDdVw3M=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    gobject-introspection
    makeWrapper
  ];

  buildInputs = [
    gtk3
  ];

  dontBuild = true;
  doCheck = false;
  dontWrapGApps = true;

  runtimeDeps = with pkgs; [
    # --- direct from DEBIAN/control `Depends:` ---
    samba
    fsarchiver
    partclone
    pv
    pigz
    nmap
    os-prober
    gvfs
    cifs-utils
    sshfs
    sshpass
    nfs-utils
    file
    xdg-utils
    libnotify
    lshw
    pciutils
    yad
    hdparm
    pbzip2
    lzop
    pixz
    plzip
    lrzip
    zstd
    fatresize
    archivemount
    nbd
    lvm2
    binutils
    smartmontools
    qemu-utils   # qemu-img, qemu-nbd
    efibootmgr
    # bsdmainutils removed — provided by util-linux below

    # --- not declared in Depends but invoked at runtime ---
    multipath-tools   # kpartx
    procps            # pkill
    kmod              # modprobe, modinfo, lsmod
    nbdkit
    openssh
    systemd           # shutdown
    stdenv.cc.libc    # getconf
    dmidecode
    lz4
    xz
    bzip2
    gzip
    btrfs-progs
    xfsprogs
    nilfs-utils
    parted
    e2fsprogs
    dosfstools
    ntfs3g
    gptfdisk
    util-linux      # covers hexdump, col, column, etc. (was bsdmainutils)
    mtools
    rsync
    cryptsetup
    mdadm
    squashfsTools
    bash
    coreutils
    findutils
    gnused
    gawk
    gnugrep
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share $out/lib
    mkdir -p $out/lib/python3/dist-packages

    # Copy from the store path. `cp -a` preserves the read-only (0444/0555)
    # modes of the Nix store, so make the copy writable or every in-place
    # edit below fails.
    cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/lib/python3/dist-packages/. \
          $out/lib/python3/dist-packages/
    cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/rescuezilla/. \
          $out/share/rescuezilla/
    chmod -R u+w $out

    # Rewrite the hardcoded FHS paths. --replace-fail makes the build abort if
    # the pattern is ever missing, instead of silently shipping /usr/share paths
    # (note: `find -exec ... \;` swallows the command's exit status, which is
    # how the previous version failed without any build error).
    substituteInPlace $out/lib/python3/dist-packages/rescuezilla/rescuezilla.py \
      --replace-fail "/usr/share/rescuezilla" "$out/share/rescuezilla"

    # Upstream's build script (not run here) replaces these placeholders from
    # `git describe` / `git show`. The tarball has no .git, so set them here.
    # GIT_COMMIT_DATE is the commit date of the release tag, in the same
    # %Y-%m-%dT%H%M%S format upstream uses.
    substituteInPlace $out/share/rescuezilla/VERSION \
      --replace-fail "VERSION-SUBSTITUTED-BY-BUILD-SCRIPT" "${finalAttrs.version}"
    substituteInPlace $out/share/rescuezilla/GIT_COMMIT_DATE \
      --replace-fail "GIT-COMMIT-DATE-SUBSTITUTED-BY-BUILD-SCRIPT" "2026-05-15T215517"

    # Byte-compile now (hash-checked, so the .pyc files are reproducible).
    # Otherwise Python recompiles on every start, since the store is read-only.
    ${pythonEnv}/bin/python -m compileall -q --invalidation-mode checked-hash \
      $out/lib/python3/dist-packages

    # Safety net: no Python file may still reference the FHS location.
    if grep -rn "/usr/share/rescuezilla" $out/lib/python3/dist-packages; then
      echo "unpatched /usr/share/rescuezilla references remain" >&2
      exit 1
    fi

    # Desktop integration files, surfaced at XDG-standard locations.
    if [ -d ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/applications ]; then
      mkdir -p $out/share/applications
      cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/applications/*.desktop \
            $out/share/applications/
      chmod u+w $out/share/applications/*.desktop
      # Rescuezilla needs root. run0 (systemd) starts the app in a clean root
      # context, so forward the variables GTK needs to reach the user's display.
      for f in $out/share/applications/*.desktop; do
        [ -e "$f" ] || continue
        substituteInPlace "$f" \
          --replace-fail "Exec=/usr/sbin/rescuezilla" \
            "Exec=${lib.getExe' systemd "run0"} --setenv=WAYLAND_DISPLAY --setenv=XDG_RUNTIME_DIR --setenv=DISPLAY --setenv=XAUTHORITY $out/bin/rescuezilla"
      done
    fi
    if [ -d ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/icons ]; then
      mkdir -p $out/share/icons
      cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/icons/. $out/share/icons/
    fi
    if [ -d ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/metainfo ]; then
      mkdir -p $out/share/metainfo
      cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/metainfo/. $out/share/metainfo/
    fi
    if [ -d ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/locale ]; then
      mkdir -p $out/share/locale
      cp -a ${finalAttrs.src}/src/apps/rescuezilla/rescuezilla/usr/share/locale/. $out/share/locale/
    fi

    runHook postInstall
  '';

  postFixup = ''
    rm -f $out/bin/rescuezilla

    makeWrapper ${pythonEnv}/bin/python3 $out/bin/rescuezilla \
      --add-flags "$out/lib/python3/dist-packages/rescuezilla/rescuezilla.py" \
      --prefix PYTHONPATH : "$out/lib/python3/dist-packages" \
      --set PATH "${lib.makeBinPath finalAttrs.runtimeDeps}:/run/wrappers/bin" \
      --set-default MODULE_DIR /run/booted-system/kernel-modules/lib/modules \
      --set PYTHONWARNINGS "ignore::SyntaxWarning" \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = with lib; {
    description = "GUI backup/restore tool and live Linux distro, a Clonezilla alternative";
    homepage = "https://rescuezilla.com/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    mainProgram = "rescuezilla";
  };
})
