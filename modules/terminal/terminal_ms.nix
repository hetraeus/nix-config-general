{ flake.homeModules.terminal_ms = { pkgs, lib, ... }: {
  home.packages = [ pkgs.powershell ];
  home.shellAliases.powershell = "echo -en \"\\e]2;🪟 Poweshell\\a\"; ${lib.getExe pkgs.powershell}";
};}
