{
  lib,
  stdenv,
  qt6,
  cmake,
  ninja,
  makeWrapper,
  coreutils,
  util-linux,
  wl-clipboard,
  clipboard-client
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "clipboard-server";
  version = "0.1.0";

  src = ./server;

  nativeBuildInputs = [
    cmake
    ninja
    makeWrapper
    qt6.wrapQtAppsHook
    qt6.qttools
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtsvg
  ];

  env.LC_ALL = "C.UTF-8";

  cmakeFlags = [
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
  ];

  qtWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [
      clipboard-client
      util-linux
      coreutils
      wl-clipboard
    ]}"
  ];

  meta = {
    description = "Quickshell clipboard manager server";
    mainProgram = "clipboard-server";
  };
})
