{ flake.nixosModules.hardware = { pkgs, inputs, config, ... }: {

  services.fwupd.enable = true;
  boot.uki.tries = 3;
  environment.systemPackages = [
    pkgs.pciutils pkgs.gparted
    inputs.multios-usb.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  services.opensnitch.rules.qqq_fwupd = {
    name        = "qqq_fwupd";
    enabled     = true;
    action      = "allow";
    duration    = "always";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
        type    = "regexp";
        operand = "process.path";
        data    = "^${config.services.fwupd.package}/bin/.fwupd(mgr|tool)-wrapped$";
        }{
        type    = "simple";
        operand = "dest.port";
        data    = "443";
        }{
        type    = "regexp";
        operand = "dest.host";
        data    = "^(|.*\.)fwupd.org$";
        }];
    };};

  # INFO: delete EFI entries
  # nix shell 'nixpkgs#efibootmgr'
  # efibootmgr
  # run0 efibootmgr --bootnum <HEX> --delete-bootnum
};}
