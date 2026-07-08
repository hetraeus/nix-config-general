{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle,
  makeWrapper,
  jre,
  libGL,
  unzip,
  wrapGAppsHook3,
}:

stdenv.mkDerivation (finalAttr: {
  pname = "morphe-cli";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-cli";
    rev = "v${finalAttr.version}";
    hash = "sha256-O3dIQ2p/02cAGpq0/vkltrXCn/dewiU2G7w+njZohfQ=";
  };

  __structuredAttrs = true;

  strictDeps = true;

  nativeBuildInputs = [
    gradle
    makeWrapper
    unzip
    wrapGAppsHook3
  ];
  buildInputs = [
    jre
    libGL
  ];

  mitmCache = gradle.fetchDeps {
    inherit (finalAttr) pname;
    data = ./deps.json;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/doc/morphe-cli" "$out/share/morphe-cli"
    install -Dm644 build/morphe-cli.jar $out/share/morphe-cli.jar

    makeWrapper ${jre}/bin/java $out/bin/morphe-cli \
      --add-flags "-jar $out/share/morphe-cli.jar" \
      --prefix PATH : "${lib.makeBinPath [ ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL ]}" \

    runHook postInstall
  '';

  meta = {
    description = "Command-line application that uses Morphe Patcher to patch Android apps";
    homepage = "https://github.com/MorpheApp/morphe-cli";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
    maintainers = [ lib.maintainers.hetraeus ];
    mainProgram = "morphe-cli";
  };
})
