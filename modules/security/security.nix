{ flake.nixosModules.security = { pkgs, lib, config, ... }: {

  # WARN: vulnix gives MANY false positives!
  environment.systemPackages = [ pkgs.sops pkgs.age ];

  security.sudo.enable = false;
  security.run0.enableSudoAlias = lib.mkForce true;
  # security.sudo-rs.enable    = true;
  # This prevents users that are not members of wheel from exploiting vulnerabilities in sudo such as CVE-2021-3156
  # security.sudo-rs.execWheelOnly = lib.mkForce true;
  #users.users."${config.users_list.principalUser}".extraGroups  = [ "wheel" ];

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;

  services.opensnitch.rules.git_allow = {
    name        = "git_allow";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       } {
       type    = "regexp";
       operand = "process.path";
       data    = "/nix/store/.*-git-.*/libexec/git-core/git-remote-http";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(github\.com|gitlab\.com|git\.kernel\.org|bitbucket\.org|gitlab\.gnome\.org|invent\.kde\.org|git\.sr\.ht|codeberg\.org)$";
       } {
       type    = "regexp";
       operand = "user.id";
       data    = "^(${toString config.users_list.principalUserUid})$";
       }];
    };};

  services.opensnitch.rules.dev_node_allowed = {
    name        = "dev_node_allowed";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       } {
       type    = "regexp";
       operand = "process.path";
       data    = "/nix/store/.*-nodejs-.*/bin/node";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(registry\.npmjs\.org)$";
       } {
       type    = "regexp";
       operand = "user.id";
       data    = "^(${toString config.users_list.principalUserUid})$";
       }];
    };};

  services.opensnitch.rules.dev_github_allowed = {
    name        = "dev_github_allowed";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(api\.github\.com|api\.individual\.githubcopilot\.com)$";
       }];
    };};
  };

flake.homeModules.security = { pkgs, ... }: {
  services.opensnitch-ui.enable = true;
  home.packages = [ pkgs.opensnitch-ui ];
};}
