{
  stdenv,
  makeWrapper,
  coreutils,
  wl-clipboard,
  quickshell
}:
 stdenv.mkDerivation {
    pname = "clipboard-client";
    version = "0.1.0";
    src = ./.;

    nativeBuildInputs = [
      makeWrapper
    ];

    buildInputs = [
      coreutils
      wl-clipboard
      quickshell
    ];

    installPhase = ''
      mkdir -p $out/share/clipboard-client
      cp -r client/qml $out/share/clipboard-client/

      mkdir -p $out/bin
      makeWrapper ${quickshell}/bin/quickshell $out/bin/clipboard-client \
        --add-flags "-p $out/share/clipboard-client/qml/main.qml" \
        --prefix PATH : ${wl-clipboard}/bin \
        --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qt-6/qml \
        --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qt6/qml \
        --prefix QML2_IMPORT_PATH : ${quickshell}/lib/qml \
        --prefix LD_LIBRARY_PATH : ${quickshell}/lib
    '';

    meta = {
      description = "Quickshell clipboard manager client";
      mainProgram = "clipboard-client";
    };
}
