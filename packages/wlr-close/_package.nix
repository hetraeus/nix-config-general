{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname   = "wlr-close";
  version = "0.1.0";

  src        = pkgs.lib.cleanSource ./.;
  strictDeps = true;

  nativeBuildInputs = [
    pkgs.wayland-scanner
    pkgs.pkg-config
  ];

  buildInputs = [ pkgs.wayland ];

  buildPhase = ''
    runHook preBuild

    proto=${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-foreign-toplevel-management-unstable-v1.xml

    wayland-scanner client-header "$proto" \
      wlr-foreign-toplevel-management-unstable-v1-client-protocol.h
    wayland-scanner private-code  "$proto" \
      wlr-foreign-toplevel-management-unstable-v1-protocol.c

    $CC -O2 -Wall -Wextra \
        $(pkg-config --cflags wayland-client) \
        -o wlr-close \
        main.c \
        wlr-foreign-toplevel-management-unstable-v1-protocol.c \
        $(pkg-config --libs wayland-client)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 wlr-close $out/bin/wlr-close
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Close the active Wayland toplevel window via wlr-foreign-toplevel-management";
    license     = licenses.mit;
    platforms   = platforms.linux;
    mainProgram = "wlr-close";
  };
}
