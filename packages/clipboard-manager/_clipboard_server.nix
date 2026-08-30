{
  stdenv,
  qt6,
  wl-clipboard,
  cmake,
  makeWrapper
}:
stdenv.mkDerivation {
  pname = "clipboard-server";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [
    cmake
    makeWrapper
    qt6.wrapQtAppsHook
    qt6.qttools
  ];
  buildInputs = [ 
    qt6.qtbase 
    qt6.qtsvg
    wl-clipboard 
  ];
  env.LC_ALL = "C.UTF-8";
  cmakeDir = "../server";

  postFixup = ''
    wrapProgram $out/bin/clipboard-server \
      --prefix PATH : ${wl-clipboard}/bin \
      --prefix PATH : $out/bin
  '';
}
