{ perSystem = { pkgs, ... }: {
  packages.cdw = pkgs.writeShellApplication {
    name          = "cdw";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify pkgs.sox ];
    text          = builtins.readFile ./cdw;
  };
};}
