{ flake.homeModules.nix_aliases = { pkgs, lib, ... }: let

pp_derivation_listfiles = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.findutils ];
  name = "pp_derivation_listfiles";
  text = ''
    echo "$0"
    REALPATH="$(nix build "''${1:-no_matches}" --print-out-paths --no-link)"
    [[ -d "$REALPATH" ]] && find "$REALPATH"
    '';};

pp_derivation_realpath = pkgs.writeShellApplication {
  name = "pp_derivation_realpath";
  text = ''
    echo "$0"
    nix build "''${1:-no_matches}" --print-out-paths --no-link
    '';};

pp_prefetch-sri     = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.jq ];
  name = "pp_prefetch-sri";
  text = ''
    nix store prefetch-file --hash-type sha256 --json "$1" | jq --raw-output '.hash'
    '';};

pp_prefetch-sri-zip = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.jq ];
  name = "pp_prefetch-sri-zip";
  text = ''
    nix store prefetch-file --hash-type sha256 --json "$1" --unpack | jq --raw-output '.hash'
    '';};

pp_list_package_files_from_command = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.findutils ];
  name = "pp_list_package_files_from_command";
  text = ''
    COMMAND_DIR="$(readlink --canonicalize-existing  "$(command -v "$1")")"
    COMMAND_DIR="''${COMMAND_DIR%/*}"
    COMMAND_DIR="''${COMMAND_DIR%/*}"
    find "$COMMAND_DIR"
    '';};

pp_find_package_providing_file = pkgs.writeShellApplication {
  name = "pp_find_package_providing_file";
  text = ''
    printf 'use: nix-locate %s' "$1"
    '';};

pp_du               = pkgs.writeShellApplication {
  name = "pp_du";
  text = ''
    COMMAND_DIR="$(readlink --canonicalize-existing  "$(command -v "$1")")"
    COMMAND_DIR="''${COMMAND_DIR%/*}"
    COMMAND_DIR="''${COMMAND_DIR%/*}"
    nix path-info --human-readable --size --closure-size "$COMMAND_DIR"
    '';};

pp_build_package    = pkgs.writeShellApplication {
  name = "pp_build_package";
  text = ''
    nix build --impure --expr '(import <nixpkgs> {}).callPackage ./package.nix {}'
    '';};

in {

  home.packages = [
    pp_derivation_realpath
    pp_derivation_listfiles
    pp_prefetch-sri
    pp_prefetch-sri-zip
    pp_list_package_files_from_command
    pp_find_package_providing_file
    pp_build_package
    pp_du
    ];

  programs.nix-init.enable = true;
  home.shellAliases.pp_list_pkgs = "nix path-info --recursive /run/current-system | ${lib.getExe' pkgs.coreutils "cut"} --delimiter='-' --fields=2- | ${lib.getExe' pkgs.coreutils "sort"} --uniq";
  home.shellAliases.pp_optimise  = "${lib.getExe' pkgs.systemd "run0"} nix store optimise";
  home.shellAliases.pp_deadcode  = "nix run github:astro/deadnix";
  home.shellAliases.pp_format    = "nix run 'nixpkgs#treefmt' -- ";
  home.shellAliases.pp_list_generations = "${lib.getExe pkgs.nh} os info";
  home.shellAliases.cd_profile-sys = "cd /run/current-system/sw/ ; ls";
  home.shellAliases.cd_profile-usr = "cd /etc/profiles/per-user/$USER/ ; ls";
};}
