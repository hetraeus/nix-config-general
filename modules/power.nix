{ flake.nixosModules.power = { pkgs, lib, self, ... }: {

environment.systemPackages = [
  self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-boot-this-now
  ];

services.logind.settings.Login = {
  HandlePowerKey               = "ignore";
  HandleSuspendKey             = "ignore";
  HandleHibernateKey           = "ignore";
  HandleLidSwitch              = "ignore";
  HandleLidSwitchExternalPower = "ignore";
  HandlePowerKeyLongPress    = "poweroff";
  };

environment.shellAliases = {
#  pwr_zzz = " xset dpms force   off ";
  pwr_cya = " ${lib.getExe' pkgs.systemd "systemctl"} hibernate    --when";
  pwr_sby = " ${lib.getExe' pkgs.systemd "systemctl"} hybrid-sleep --when";
  "q\\#"  = " ${lib.getExe' pkgs.systemd "systemctl"} poweroff     --when";
  "rh\\#" = " ${lib.getExe' pkgs.systemd "systemctl"} reboot       --when";
  "rs\\#" = " ${lib.getExe' pkgs.systemd "systemctl"} soft-reboot        "; # BUG: this one is not controllable by polkit https://man.archlinux.org/man/org.freedesktop.login1.5.en
  # do not make a countdown to shutdown!
  # just use systemctl poweroff --when=
  # or the alias with --when=
  };

security.polkit.enable = true; # allow nix shell 'nixpkgs#gparted' --command gparted
security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (
      subject.isInGroup("users")
        && (
          action.id == "org.freedesktop.login1.reboot" ||
          action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
          action.id == "org.freedesktop.login1.power-off" ||
          action.id == "org.freedesktop.login1.power-off-multiple-sessions"
        )
      )
    {
      return polkit.Result.YES;
    }
  });
  '';
};}
