{ flake.nixosModules.documentation = { pkgs, self, ... }: {
  documentation.man.cache.enable = true; # make man -k / man --apropos / apropos working
  
  services.opensnitch.rules.rfc-editor = {
    name        = "rfc-editor";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(rsync\.rfc-editor\.org)$";
       } {
       type     = "simple";
       operand  = "dest.port";
       data     = "873";
       }];
    };};

  environment.systemPackages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-rfc
    pkgs.inxi
    pkgs.lshw
    pkgs.smartmontools
    pkgs.linux-doc
    ];
  };


flake.homeModules.documentation = { pkgs, lib, config, self, ... }: {

  programs.fastfetch.enable = true;
  programs.navi.enable      = true;
  programs.anki.enable      = true;
  programs.tealdeer.enable  = true; # needed by navi
  home.shellAliases.info    = "${lib.getExe pkgs.pinfo}";
  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-docs
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-linux-subsystems
    pkgs.inxi
    pkgs.lshw
    ];
  programs.firefox.profiles.user.bookmarks = {
    force = true;
    settings  = [{
      name    = "Nixos hydra packages build jobs view";
      keyword = "hydra";
      url     = "https://hydra.nixos.org/jobset/nixos/trunk-combined";
    }];};
  };
}
