{ perSystem = { pkgs, ... }: {
  packages.freecad = let
    SearchBar = pkgs.fetchFromGitHub {
      owner = "APEbbers";
      repo  = "SearchBar";
      rev   = "v1.6.2";
      hash  = "sha256-dw6U60276YobGtUI35aAeWXhydnpjWKFgEQNVBOQxHQ=";
    };
    FastenersWB = pkgs.fetchFromGitHub {
      owner = "shaise";
      repo  = "FreeCAD_FastenersWB";
      rev   = "V0.5.43-beta";
      hash  = "sha256-mYg8M1APYtleQVgnVvGtpRQ/z90RvGK2v+FkHEBFfj0=";
    };
    OpenTheme = pkgs.fetchFromGitHub {
      owner = "obelisk79";
      repo  = "OpenTheme";
      rev   = "a3d302cba6dc633038ccbd136f52490886a9391e";
      hash  = "sha256-UwJV0yRUir+4bvcACgOs+mEAWa35CKt0s4PDGe03HZY=";
    };
  in pkgs.freecad-qt6.customize {
    # BUG: read-only file system
    # ribbon = pkgs.fetchFromGitHub {
    #   owner = "APEbbers";
    #   repo  = "FreeCAD-Ribbon";
    #   rev   = "v1.10.10.2";
    #   hash  = "sha256-L1dlc8FTme7X3uS6s66xmRXkHb/CFdwiblk0otr0oz8=";
    # };
    modules = [ SearchBar FastenersWB OpenTheme ];
    pythons = [ (ps: [ ps.lxml ps.requests ]) ];
  };
};}
