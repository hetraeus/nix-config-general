{ flake.homeModules.file_manager = { config, pkgs, lib, self, ... } : let

fm_paste_symlinks = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.wl-clipboard-rs ];
  name = "fm_paste_symlinks";
  text = ''
    TARGET_PATH="''${1:-.}"
    mapfile -t CURR_PATHS < "$XDG_RUNTIME_DIR"/copied_paths
    notify-send --app-name="fm_paste_symlink" "Symlinking" "''${CURR_PATHS[@]}"

    for each_file in "''${CURR_PATHS[@]}"; do
      [[ -e "$each_file" ]] && { ln --symbolic -- "''${each_file#file:\/\/}" "$TARGET_PATH" ; }
      done
  '';};

fm_checksums     = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-checksums;
fm_share         = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-share;
fm_image_convert = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-image-convert;
xxx              = self.packages.${pkgs.stdenv.hostPlatform.system}.xxx;
run_or_raise     = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.wrun-or-raise}";
in {

  xdg.mimeApps.enable     = true;
  home.packages = [
    pkgs.lxqt.pcmanfm-qt
    pkgs.libarchive

    pkgs.edir

    # Thumbnails
    pkgs.ffmpegthumbnailer
    pkgs.kdePackages.kimageformats
    # f3d for 3d objext is too heavy! Declared in the maker module
    self.packages.${pkgs.stdenv.hostPlatform.system}.mkweblink
    ];


  programs.qimgv.extraPackages = [
    fm_share
    fm_checksums
    fm_image_convert
    pkgs.kitty
    pkgs.gmic-qt
    pkgs.libheif
    ];

  programs.qimgv.settings.Scripts = {
      "script\\1\\name"="fm_checksums";
      "script\\1\\value"="\"@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\aScript\\0\\0\\0\\0`\\0k\\0i\\0t\\0t\\0y\\0 \\0-\\0-\\0\\x61\\0p\\0p\\0-\\0i\\0\\x64\\0=\\0\\\"\\0\\x66\\0m\\0\\x65\\0n\\0u\\0_\\0p\\0\\x61\\0n\\0\\x65\\0l\\0\\\"\\0 \\0\\x66\\0m\\0_\\0\\x63\\0h\\0\\x65\\0\\x63\\0k\\0s\\0u\\0m\\0s\\0 \\0%\\0\\x66\\0i\\0l\\0\\x65\\0%\\0)\"";
      "script\\2\\name"="fm_image_convert";
      "script\\2\\value"="\"@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\aScript\\0\\0\\0\\0h\\0k\\0i\\0t\\0t\\0y\\0 \\0-\\0-\\0\\x61\\0p\\0p\\0-\\0i\\0\\x64\\0=\\0\\\"\\0\\x66\\0m\\0\\x65\\0n\\0u\\0_\\0p\\0\\x61\\0n\\0\\x65\\0l\\0\\\"\\0 \\0\\x66\\0m\\0_\\0i\\0m\\0\\x61\\0g\\0\\x65\\0_\\0\\x63\\0o\\0n\\0v\\0\\x65\\0r\\0t\\0 \\0%\\0\\x66\\0i\\0l\\0\\x65\\0%\\0)\"";
      "script\\3\\name"="fm_share";
      "script\\3\\value"="\"@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\aScript\\0\\0\\0\\0X\\0k\\0i\\0t\\0t\\0y\\0 \\0-\\0-\\0\\x61\\0p\\0p\\0-\\0i\\0\\x64\\0=\\0\\\"\\0\\x66\\0m\\0\\x65\\0n\\0u\\0_\\0p\\0\\x61\\0n\\0\\x65\\0l\\0\\\"\\0 \\0\\x66\\0m\\0_\\0s\\0h\\0\\x61\\0r\\0\\x65\\0 \\0%\\0\\x66\\0i\\0l\\0\\x65\\0%\\0)\"";
      "script\\4\\name"="gmic";
      "script\\4\\value"="@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\aScript\\0\\0\\0\\0\\x1c\\0g\\0m\\0i\\0\\x63\\0_\\0q\\0t\\0 \\0%\\0\\x66\\0i\\0l\\0\\x65\\0%\\x1)";
      "script\\size"=4;
    };

  # wayland.windowManager.hyprland.extraLuaFiles.file_manager = ''
   wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + E", hl.dsp.exec_cmd("${run_or_raise} pcmanfm-qt pcmanfm-qt"))
    '';

  xdg.autostart.enable = true;

  # xdg.autostart.entries = lib.singleton (
  #   pkgs.makeDesktopItem {
  #     name = "desktop_icons";
  #     desktopName = "Add icons to desktop";
  #     exec = "${lib.getExe pkgs.pcmanfm-qt} --desktop";
  #     } + /share/applications/desktop_icons.desktop
  #   );};

  systemd.user.services.pcmanfm_desktop = {
    Service.ExecStart  = "${lib.getExe pkgs.pcmanfm-qt} --desktop --daemon-mode";
    Service.Restart    = "on-failure";
    Unit.Description   = "pcmanfm desktop";
    Unit.After         = [ "graphical-session.target" ] ;
    Unit.Wants         = [ "graphical-session.target" ] ;
    Install.WantedBy   = [ "graphical-session.target" ] ;
    Service.KillMode   = "process";
    Service.Slice      = "background.slice";
    };

  gtk.gtk3.bookmarks = [
    "file://${config.xdg.userDirs.documents}    proj"
    "file://${config.xdg.userDirs.music} ♪   mus"
    "file://${config.xdg.userDirs.pictures} 󱦌   pics"
    "file://${config.xdg.userDirs.videos}    mov"
    "file://${config.xdg.userDirs.download} 󰇚  dwld"
    "file://${config.xdg.userDirs.publicShare}   cifs"
    "file:///tmp ᴛᴍᴘ"
    ];

  xdg.dataFile."file-manager/actions/fm_checksum.desktop".text = ''
  [Desktop Entry]
  Type=Action
  Profiles=profile_id
  Name=checksum
  Icon=application-x-sharedlib

  [X-Action-Profile profile_id]
  MimeTypes=all/allfiles
  Exec=${lib.getExe pkgs.kitty} --app-id=fmenu_panel ${lib.getExe fm_checksums} %F
  '';

  xdg.dataFile."file-manager/actions/fm_share.desktop".text = ''
  [Desktop Entry]
  Type=Action
  Profiles=profile_id
  Name=share
  Icon=share

  [X-Action-Profile profile_id]
  MimeTypes=all/allfiles;inode/directory
  Exec=${lib.getExe pkgs.kitty} --app-id=fmenu_panel ${lib.getExe fm_share} %F
  '';

  xdg.dataFile."file-manager/actions/xxx.desktop".text = ''
  [Desktop Entry]
  Type=Action
  Profiles=profile_id
  Name=extract
  Icon=zip

  [X-Action-Profile profile_id]
  MimeTypes=all/allfiles;inode/directory
  Exec=${lib.getExe pkgs.kitty} --app-id=fmenu_panel ${lib.getExe xxx} %F
  '';

  # TEST
  xdg.dataFile."file-manager/actions/fm_paste_symlinks.desktop".text = ''
  [Desktop Entry]
  Type=Action
  Profiles=profile_id
  Name=paste symlink
  Icon=emblem-symbolic-link

  [X-Action-Profile profile_id]
  MimeTypes=inode/directory
  Exec=${lib.getExe fm_paste_symlinks} %f
  '';

  xdg.dataFile."file-manager/actions/fm_image_convert.desktop".text = ''
  [Desktop Entry]
  Type=Action
  Profiles=profile_id
  Name=image convert
  Icon=color

  [X-Action-Profile profile_id]
  MimeTypes=image/*
  Exec=${lib.getExe pkgs.kitty} --app-id=fmenu_panel ${lib.getExe fm_image_convert} %F
  '';

  xdg.configFile."pcmanfm-qt" = { source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/../config/pcmanfm-qt"; };

  # Drop here template files used by file managers -> right click -> create new
  xdg.userDirs.templates     = "${config.xdg.dataHome}/templates";

  home.file."${config.xdg.userDirs.templates}/weblink.html".text = ''
    <!DOCTYPE html>
    <title></title>
    <meta http-equiv="refresh" content="0; url=" />
    '';
};}
