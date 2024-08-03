{ lib, pkgs, ... }: {
  environment.variables.EDITOR = "${lib.getExe pkgs.helix}";
  environment.shellAliases.v   = "$EDITOR";
}
