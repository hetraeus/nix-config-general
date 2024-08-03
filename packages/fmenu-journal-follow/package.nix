{ perSystem = { pkgs, ... }: {
  packages.fmenu-journal-follow = pkgs.writeShellApplication {
    name          = "fmenu-journal-follow";
    text          = builtins.readFile ./fmenu-journal-follow;
    runtimeInputs = [
      pkgs.fzf pkgs.systemd pkgs.wl-clipboard-rs
      pkgs.coreutils # needs stty
    ];
  };
};}
