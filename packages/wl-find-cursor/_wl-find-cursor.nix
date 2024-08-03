{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  wayland,
  wayland-protocols,
  wayland-scanner
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wl-find-cursor";
  version = "0-unstable-2026-02-03";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "cjacker";
    repo = "wl-find-cursor";
    rev = "ce1a125702b466dc537c5490f7888b4a68dee883";
    hash = "sha256-IUreWEOWF1loS5SiAh8XPFrKE35Pxv6e8hhvdtNvjiU=";
  };

  # Fix the hardcoded /usr/share path and a broken Makefile dependency
  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail "/usr/share/wayland-protocols" "${wayland-protocols}/share/wayland-protocols" \
      --replace-fail "install: default" "install: all"
  '';

  nativeBuildInputs = [
    wayland-scanner
  ];

  # Add the required Wayland libraries and protocols
  buildInputs = [
    wayland
    wayland-protocols
  ];

  # Ensure the binary installs to the correct Nix store path
  installFlags = [ "PREFIX=$(out)" "DESTDIR=" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Highlight and print out global mouse position in wayland, especially for compositors based on wlroots, such as sway";
    homepage = "https://github.com/cjacker/wl-find-cursor";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ hetraeus ];
    mainProgram = "wl-find-cursor";
    platforms = lib.platforms.linux;
  };
})
