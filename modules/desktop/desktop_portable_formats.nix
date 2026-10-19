{ ... }: { flake.nixosModules.desktop_portable_formats = { pkgs, lib, ... }: {

  services.flatpak.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
     extraPkgs = pkgs: with pkgs; [
        # --- Base & Compression ---
        zlib
        bzip2
        icu

        # --- Audio ---
        alsa-lib
        pipewire
        ffmpeg

        # --- Graphics, GUI, & Fonts ---
        cairo
        cups
        expat
        fontconfig
        freetype
        fribidi
        gdk-pixbuf
        glib
        gtk3
        glibcLocales
        harfbuzz
        libglvnd
        libdrm
        libgbm
        libxkbcommon
        pango
        libX11
        libice
        libsm
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxscrnsaver
        libxtst
        libxcb
        qt5.qtwayland
        qt6.qtwayland

        # --- System & Security ---
        dbus
        e2fsprogs    # Provides libcom_err
        libapparmor
        libcap
        libcap_ng
        libgcrypt
        libgpg-error
        gpgmepp
        libksba
        libselinux
        libseccomp
        linux-pam
        npth
        systemd      # Provides libudev
        util-linux   # Provides libmount, libuuid
        udev

        # --- Cryptography & Networking ---
        gnutls
        libassuan
        nspr
        nss

        # --- Other Libraries ---
        e2fsprogs
        imagemagick
        libxcrypt
        libxcrypt-legacy # Provides libcrypt.so.1
        ncurses
        perl
        readline
        sqlite
        stdenv.cc.cc.lib # Provides libstdc++.so.6
        libxau
        libxdmcp
        libxshmfence

        ];
      };
    };

  services.opensnitch.rules.flk-flatpak = {
    name        = "flk-flatpak";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "process.command";
       data     = "${lib.getExe' pkgs.flatpak ".flatpak-wrapped"}";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(ciscobinary\.openh264\.org|dl\.flathub\.org)$";
       } {
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       }];
    };};

};

flake.homeModules.desktop_portable_formats = { pkgs, config, ... }: {
  home.packages = [ pkgs.flatpak ];
  # BUG: https://github.com/gmodena/nix-flatpak/issues/31
  # Hide warning about showing the program in the menu
  xdg.systemDirs.data  = [ "${config.xdg.dataHome}/flatpak/exports/share" ];
};}
