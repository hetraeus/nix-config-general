{
  stdenv,
  cmake,
  ninja,
  qt6,
  makeWrapper,
  coreutils,
  wl-clipboard,
  quickshell
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "clipboard-client";
  version = "0.1.0";

  src = builtins.path {
    path = ./client;
    filter = path: type:
      let base = baseNameOf path;
      in base != "build" && base != ".direnv";
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    coreutils
    wl-clipboard
    quickshell
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  postInstall = ''
    qmldir=$(find . -name qmldir -type f | head -n1)
    if [ -z "$qmldir" ]; then
      echo "ERROR: no qmldir found anywhere in the build tree" >&2
      echo "Listing all .qml-related files for diagnosis:" >&2
      find . -name '*.qml*' -o -name 'qmldir*' >&2
      exit 1
    fi
    echo "Installing qmldir from: $qmldir"
    mkdir -p $out/lib/qml/ClipboardClient
    cp "$qmldir" $out/lib/qml/ClipboardClient/qmldir

    mkdir -p $out/bin
    makeWrapper ${quickshell}/bin/quickshell $out/bin/clipboard-client \
      --add-flags "-p $out/share/clipboard-client/shell.qml" \
      --prefix PATH : ${wl-clipboard}/bin \
      --prefix QML2_IMPORT_PATH : $out/lib/qml \
      --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qt-6/qml \
      --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qt6/qml \
      --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qml \
      --prefix LD_LIBRARY_PATH : ${quickshell}/lib
  '';

  meta = {
    description = "Quickshell clipboard manager client";
    mainProgram = "clipboard-client";
  };
})
