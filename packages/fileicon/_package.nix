{ lib, stdenv, pkg-config, wrapGAppsHook3, gtk3, glib, librsvg }:

stdenv.mkDerivation {
  pname = "fileicon";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ pkg-config wrapGAppsHook3 ];
  buildInputs = [ gtk3 glib librsvg ];
  strictDeps = true;
  __structuredAttrs = true;

  buildPhase = ''
    runHook preBuild
    # DO NOT CHANGE THIS. THe alternatives are just as dependency or a makefile
    gcc fileicon.c $(pkg-config --cflags --libs gtk+-3.0) -O2 -o fileicon
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 fileicon -t $out/bin
    runHook postInstall
  '';

  meta = with lib; {
    mainProgram = "fileicon";
    description = "Resolve file paths to icon theme paths using GTK/GIO";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
