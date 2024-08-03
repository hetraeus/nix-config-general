{ flake.homeModules.desktop_emoji = { pkgs, lib, config, self, ... } : let
  fmenu-emoticon = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-emoticon;

in {
  systemd.user.packages = [ fmenu-emoticon ];
  home.packages = [ fmenu-emoticon ] ++
    lib.optionals (config.stylix.fonts.emoji.package == null) [ pkgs.noto-fonts-color-emoji ];
};}
