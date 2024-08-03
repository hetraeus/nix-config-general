{ flake.nixosModules.maker = { config, ... }: {

# THIS OVERLAY TRIGGERS A LONG REBUILD
# Avoid this for the time being

# nixpkgs.overlays = [ # TEST: easier cadsketch setup
#   (final: prev: {
#     blender = prev.blender.overrideAttrs (old: {
#       pythonPath = (old.pythonPath or []) ++ [pkgs.python3Packages.py-slvs];
#     });
#   })
# ];

services.opensnitch.rules.pru_api = {
  name        = "pru_api";
    enabled   = true;
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "simple";
      operand = "dest.host";
      data    = "preset-repo-api.prusa3d.com";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};


services.opensnitch.rules.pru_files = {
  name        = "pru_files";
    enabled   = true;
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "simple";
      operand = "dest.host";
      data    = "files.prusa3d.com";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

};

flake.homeModules.maker = { pkgs, self, ... }: {

  home.packages = [
    pkgs.exhibit
    pkgs.f3d    # for thumbnails. It works, verified 2025-02-23

    pkgs.dune3d
    pkgs.librecad
    pkgs.leocad
    pkgs.orca-slicer

    pkgs.blender

    self.packages.${pkgs.stdenv.hostPlatform.system}.online-editors
    self.packages.${pkgs.stdenv.hostPlatform.system}.freecad

  # pkgs.kicad # WARN: this is HEAVYWEIGHT !
    ];

  xdg.configFile."blender/${pkgs.blender.version}/scripts/addons/CAD_Sketcher" = {
    recursive = true;
    source  = pkgs.fetchFromGitHub {
      owner = "hlorus";
      repo  = "CAD_Sketcher";
      rev   = "5638e66fda36eea7f5c3671f48bf4d3776c46dcb";
      hash  = "sha256-Ba/zso/RBNSRPvu+NqVe/6XpZ1+HGPhynmsANlCdo/0=";
      };
    };

  # INFO: get SRI like this :
  # VER="v1.11.0"
  # URL="https://github.com/APEbbers/FreeCAD-Ribbon/archive/refs/tags/$VER.tar.gz"
  # nix store prefetch-file --hash-type sha256 --unpack --json "$URL" | jq --raw-output '.hash'
  xdg.dataFile."FreeCAD/Mod/Ribbon" = {
    recursive = true;
    source  = pkgs.fetchFromGitHub {
      owner = "APEbbers";
      repo  = "FreeCAD-Ribbon";
      rev   = "v1.11.0";
      hash  = "sha256-UYcPkONYQXs2ewSkfm4vMPhm44HvsGSoN+J7qd8MDvs=";
      };
    };
 xdg.mimeApps.defaultApplications = {
    "image/vnd.dxf" = [ "librecad.desktop" ];
    };
   };
}
