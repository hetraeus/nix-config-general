{ perSystem = { pkgs, ... }: {
  packages.weather = pkgs.python3Packages.buildPythonApplication (finalAttrs: {
    pname   = "weather";
    version = "0.1.0";
    format  = "other";
    propagatedBuildInputs = [
      pkgs.python3Packages.urllib3
      pkgs.python3Packages.httpx
    ];
    dontUnpack   = true;
    installPhase = ''
      install -Dm755 ${./${finalAttrs.pname}} $out/bin/${finalAttrs.pname}
    '';
  });
};}
