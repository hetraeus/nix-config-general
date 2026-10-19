{ perSystem = { pkgs, ... }: {
  packages.fmenu-journal-follow = pkgs.writeShellApplication {
    name          = "fmenu-journal-follow";
    text          = builtins.readFile ./fmenu-journal-follow;
    runtimeInputs = [
      pkgs.fzf
      pkgs.systemd # don't use systemdMinimal, because it doesn't handle the compression
      pkgs.wl-clipboard-rs
      pkgs.coreutils # needs stty
    ];
  };
};}
