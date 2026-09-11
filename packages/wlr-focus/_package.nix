{ pkgs ? import <nixpkgs> {} }:

let
  proto = "${pkgs.wlr-protocols}/share/wlr-protocols/unstable/wlr-foreign-toplevel-management-unstable-v1.xml";
in
pkgs.stdenv.mkDerivation {
  pname   = "wlr-focus";
  version = "0.1.0";

  # Local directory source: strip .git/, editor backups, etc.
  # (nixpkgs proper almost never needs this because fetchFromGitHub /
  # fetchurl tarballs already exclude those.)
  src = pkgs.lib.cleanSource ./.;

  strictDeps = true;

  nativeBuildInputs = [
    pkgs.wayland-scanner
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.wayland
  ];

  buildPhase = ''
    runHook preBuild

    wayland-scanner client-header ${proto} \
      wlr-foreign-toplevel-management-unstable-v1-client-protocol.h
    wayland-scanner private-code ${proto} \
      wlr-foreign-toplevel-management-unstable-v1-protocol.c

    $CC -O2 -Wall -Wextra \
        $(pkg-config --cflags wayland-client) \
        -o wlr-focus \
        main.c \
        wlr-foreign-toplevel-management-unstable-v1-protocol.c \
        $(pkg-config --libs wayland-client)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 wlr-focus $out/bin/wlr-focus
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Minimal Wayland toplevel focus utility using wlr-foreign-toplevel-management";
    license     = licenses.mit;
    platforms   = platforms.linux;
    mainProgram = "wlr-focus";
  };
}
