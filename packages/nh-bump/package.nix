{ perSystem = { pkgs, ... }: {
  packages.nh-bump = pkgs.writeShellApplication {
    name          = "nh-bump";
    runtimeInputs = [ pkgs.systemd pkgs.nh ];
    text = ''
      OP="''${1:-}"
      [[ -z "$OP" ]] && exit
      [[ "''${2:-}" == "offline" ]] && IF_OFFLINE="--offline"
      # shellcheck disable=SC2086
      systemd-inhibit \
      --what=sleep:idle:handle-lid-switch \
      --why="nixos-rebuild running"       \
        nh os "$OP" --keep-failed ''${IF_OFFLINE:=} \
        "$HOME/my/proj/sysflake" \
        --verbose --hostname="$(hostnamectl hostname)" && printf "\e]777;notify;%s;%s\a" "NixOS" "$OP creation successful"
    '';
  };
};}
