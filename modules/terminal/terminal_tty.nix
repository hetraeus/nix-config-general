{ flake.nixosModules.terminal_tty = { pkgs, lib, config, ... }: {

  # Fedora enables kmscon to
  # provide better keyboard support, and better security
  services.kmscon.enable   = true;
  services.kmscon.hwRender = true;

  services.getty.autologinUser = "${config.users_list.principalUser}";
  services.getty.autologinOnce = true;
  services.kmscon.extraConfig = "
    #blinking=on # TODO after v10.0.0
    natural-scrolling=on
    ";


  # tty welcome, used by tuigreet too
  environment.etc."issue" = { source = ./etc_issue; mode = "0444"; };

  services.greetd.enable = true;
  services.greetd.settings = {
    initial_session.command = "${lib.getExe' pkgs.hyprland "start-hyprland"}";
    initial_session.user = "${config.users_list.principalUser}";
    default_session.command = "${lib.getExe pkgs.tuigreet} --cmd ${lib.getExe' pkgs.hyprland "start-hyprland"} --issue --time";
    default_session.user = "${config.users_list.principalUser}";
    };
  };}
