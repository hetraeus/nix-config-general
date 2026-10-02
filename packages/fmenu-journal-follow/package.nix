{ perSystem = { pkgs, ... }: {
  packages.fmenu-journal-follow = pkgs.writeShellApplication {
    name          = "fmenu-journal-follow";
    text          = builtins.readFile ./fmenu-journal-follow;
    runtimeInputs = [
      pkgs.fzf pkgs.systemdMinimal pkgs.wl-clipboard-rs
      pkgs.coreutils # needs stty
    ];
  };
};}
