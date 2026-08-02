{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle,
  jre,
  makeWrapper,
  libGL,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-desktop";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-desktop";
    tag = "v${finalAttrs.version}";
    # replace with the real hash before building, e.g. via
    # `nix-prefetch-github MorpheApp morphe-desktop --rev v1.11.0`
    hash = "sha256-0000000000000000000000000000000000000000000=";
  };

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];

  # Gradle dependency lockfile - see deps.json / the update instructions below.
  # This MUST be generated on your own machine (see explanation in chat).
  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    data = ./deps.json;
  };

  # required for mitm-cache to work on Darwin, harmless elsewhere
  __darwinAllowLocalNetworking = true;

  gradleFlags = [ "-Dfile.encoding=utf-8" ];

  # build.gradle.kts declares shadowJar as "the only distribution artifact"
  gradleBuildTask = "shadowJar";

  # tests pull in mockk/junit and may need extra network-independent setup;
  # leave off until verified, then flip to `true`.
  doCheck = false;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/morphe-desktop" "$out/bin"
    install -Dm644 build/libs/morphe-desktop-*-all.jar \
      "$out/share/morphe-desktop/morphe-desktop.jar"

    makeWrapper ${lib.getExe jre} "$out/bin/morphe-desktop" \
      --add-flags "-jar $out/share/morphe-desktop/morphe-desktop.jar" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libGL ]}"

    runHook postInstall
  '';

  meta = {
    description = "Desktop patching tool for Android apps, using Morphe Patcher (CLI + Compose GUI)";
    homepage = "https://github.com/MorpheApp/morphe-desktop";
    license = lib.licenses.gpl3Plus;
    mainProgram = "morphe-desktop";
    maintainers = with lib.maintainers; [ ]; # add yourself here
    # only x86_64-linux has actually been exercised so far (per the PR checklist);
    # widen this once other platforms are confirmed to work.
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # mitm cache
    ];
  };
})
