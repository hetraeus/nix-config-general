{ self, config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    pkgs.dix
    pkgs.nix-tree
    pkgs.nix-inspect
    self.packages.${pkgs.stdenv.hostPlatform.system}.nh-bump
    ];

  nix.gc = {
    automatic  = true;
    persistent = true;
    dates  = "weekly";
  #  options = "--delete-older-than 8d";
    };

  nix.settings.cores = 2;
  nix.settings.max-jobs = 3;
  nix.daemonIOSchedPriority = 7;

  programs.nh.enable = true;
  # services.opensnitch.rules.ewr_nhwrap_nix = {
  #   name        = "ewr_nhwrap_nix";
  #   created     = "2010-01-01T10:00:00.000000Z"; # silence logs
  #   enabled     = true;
  #   action      = "allow";
  #   duration    = "always";
  #   operator    = {
  #     type      = "list";
  #     operand   = "list";
  #     sensitive = false;
  #     list      = [{
  #      type     = "simple";
  #      operand  = "process.path";
  #      data     = "${pkgs.nh}/bin/.nh-wrapped";
  #      } {
  #      type     = "simple";
  #      operand  = "dest.port";
  #      data     = "443";
  #      }];
  #   };};

  services.opensnitch.rules.eee_nh_nix = {
    name        = "eee_nh_nix";
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
        operand  = "process.path";
        data     = "^/nix/store/[a-z0-9]{32}-nh-.*/bin/nh$";
        } {
        type     = "simple";
        operand  = "dest.port";
        data     = "443";
        } {
        type    = "regexp";
        operand = "user.id";
        data    = "^(${toString config.users_list.principalUserUid})$";
        }];
    };};

  services.opensnitch.rules.ebb_nix_nix = {
    name        = "ebb_nix_nix";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       # type     = "regexp";
       # operand  = "process.path";
       # data     = "^/nix/store/[a-z0-9]{32}-nix-.*/bin/nix"; # Don't use getExe ! It doesn't follow all the store symlinks
       # } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^(((cache|channels|tarballs)\.nixos|(devenv|nix-community)\.cachix).org|(codeload.|)github.com|release-assets\.githubusercontent\.com|www\.python\.org|sourceware\.org|(ftpmirror|download\.savannah)\.gnu\.org|cache\.numtide\.com)$";
        } {
        type     = "simple";
        operand  = "dest.port";
        data     = "443";
        }];
    };};

  services.opensnitch.rules.ebd_nixd = {
    name        = "ebd_nixd";
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
        operand  = "process.path";
        data     = "${pkgs.nixd}/libexec/nixd-attrset-eval";
        } {
        type     = "simple";
        operand  = "dest.port";
        data     = "443";
        }];
      };};

    services.opensnitch.rules.nix_pref = {
      name      = "nix_pref";
      enabled   = true;
      created   = "2010-01-01T10:00:00.000000Z"; # silence logs
      action    = "allow";
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "simple";
        operand = "dest.port";
        data    = "443";
        } {
        type    = "regexp";
        operand = "user.id";
        data    = "^(${toString config.users_list.principalUserUid})$";
        } {
        type    = "regexp";
        operand = "process.command";
        data    = "^nix store prefetch-file .*$";
        }];
    };};

   multiverse = {
     enable = true;
     config.allowUnfree = true;
     cooldown.enable = true;

     # Attributes pinned to an exact version, each resolved against whichever
     # revision last shipped it.
     # pins = {
     #   vscode = "1.107.0";
     #   ripgrep = "13.0.0";
     # };

     # The same idea, maintained by `mvs lock` instead of by hand: a set of
     # commits, each moved on its own by `mvs lock update <attr>`.
     lock = ./multiverse.lock;
   };

}
