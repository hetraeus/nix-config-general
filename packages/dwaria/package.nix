{ perSystem = { pkgs, ... }: {
  packages.dwaria = pkgs.python3Packages.buildPythonApplication (finalAttrs: {
    pname   = "dwaria";
    version = "0.1.0";
    format  = "other";
    propagatedBuildInputs = [ pkgs.python3Packages.requests pkgs.aria2 ];
    dontUnpack   = true;
    installPhase = ''install -Dm755 ${./_dwaria} $out/bin/${finalAttrs.pname}'';
    meta.mainProgram = "dwaria";
  });
};}
