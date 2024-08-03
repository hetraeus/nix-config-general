{ flake.nixosModules.dev_web = { lib, pkgs, ... } : {

  services.opensnitch.rules.ast_androidstudio = {
    name        = "ast_androidstudio";
      enabled   = true;
      created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "allow";
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "simple";
        operand = "process.path";
        data    = "${lib.getExe' pkgs.android-studio ".studio-wrapped"}";
        } {
        type    = "regexp";
        operand = "dest.port";
        data    = "^(443|80)$";
        } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^(plugins\.jetbrains|downloads\.marketplace\.jetbrains|play\.google|dl\.google|developer\.android)\.com$";
        }];
    };};

  };

  flake.homeModules.dev_web = { pkgs, ... } : {
    home.packages = [ pkgs.android-studio ];
};}
