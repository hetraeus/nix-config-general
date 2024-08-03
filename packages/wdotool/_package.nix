{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libxkbcommon,
  stdenv,
  wayland,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "wdotool";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "cushycush";
    repo = "wdotool";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kmEMkkU5cy2AqEzbpm4Dp+FzguzldzWqD5KSr7uskLE=";
  };

  # cargoHash = "sha256-hKulp8QC8emC1XXSRdhBefO1XcThveybjPfagJs3u5A=";
  cargoHash = "sha256-0sifatYl+aGX+on2mXlMJg7/zKjpORNV3pEv9ZcdZZI=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libxkbcommon
  ]
  ++ lib.optionals stdenv.isLinux [
    wayland
  ];

  meta = {
    description = "Xdotool-compatible input automation for Wayland, built on libei + wlroots protocols (not /dev/uinput";
    homepage = "https://github.com/cushycush/wdotool";
    changelog = "https://github.com/cushycush/wdotool/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ hetraeus ];
    mainProgram = "wdotool";
  };
})
