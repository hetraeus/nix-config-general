{ pkgs, lib, ... }:

pkgs.stdenv.mkDerivation {
  pname = "cursor-ring";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    pkg-config
    wayland-scanner
  ];

  buildInputs = with pkgs; [
    wayland
    wayland-protocols
    cairo
  ];

  postPatch = ''
    # Generate wlr-layer-shell protocol
    wayland-scanner client-header wlr-layer-shell-unstable-v1.xml \
      wlr-layer-shell-unstable-v1-client-protocol.h
    wayland-scanner private-code wlr-layer-shell-unstable-v1.xml \
      wlr-layer-shell-unstable-v1-protocol.c

    # Generate xdg-shell protocol (required by wlr-layer-shell for popups)
    wayland-scanner client-header \
      "${pkgs.wayland-protocols}/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml" \
      xdg-shell-client-protocol.h
    wayland-scanner private-code \
      "${pkgs.wayland-protocols}/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml" \
      xdg-shell-protocol.c
  '';

  buildPhase = ''
    runHook preBuild
    gcc -O2 -Wall -o cursor-ring \
      cursor-ring.c \
      wlr-layer-shell-unstable-v1-protocol.c \
      xdg-shell-protocol.c \
      $(pkg-config --cflags --libs wayland-client cairo) -lm
  '';

  installPhase = ''
    install -Dm755 cursor-ring $out/bin/cursor-ring
  '';

  meta = {
    description = "A pulsing cursor highlight ring for Wayland compositors";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "cursor-ring";
  };
}
