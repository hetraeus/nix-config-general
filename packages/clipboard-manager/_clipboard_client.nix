{
  lib,
  rustPlatform,
  pkg-config,
  makeWrapper,
  coreutils,
  dbus,
  wayland,
  mold,
  libxkbcommon,
  vulkan-loader,
  libGL
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "clipboard-client";
  version = "0.1.0";

  src = builtins.path {
    path = ./client;
    filter = path: type:
      let base = baseNameOf path;
      in base != "target"
         && base != ".direnv"
         && base != "result"
         && base != "Cargo.lock.orig";
  };

  cargoLock.lockFile = ./client/Cargo.lock;
  RUSTFLAGS = "-C link-arg=-fuse-ld=mold";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    mold
  ];

  buildInputs = [
    # Iced uses wgpu by default; wgpu needs a Vulkan/GL loader at runtime.
    vulkan-loader
    libGL

    # iced-layershell talks to the Wayland compositor directly.
    wayland
    libxkbcommon

    # zbus is pure-Rust, but the session bus address is inherited from the
    # user environment; keeping dbus in buildInputs guarantees the client
    # links against a known-good libdbus if any transitive dep needs it.
    dbus
  ];

  postInstall = ''
    wrapProgram $out/bin/clipboard-client \
      --prefix PATH : ${lib.makeBinPath [ coreutils dbus ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        vulkan-loader
        libGL
        wayland
        libxkbcommon
      ]}

    mkdir -p $out/share/systemd/user
    cat > $out/share/systemd/user/clipboard-client.service <<EOF
[Unit]
Description=clipboard-client
After=graphical-session.target clipboard-server.service
Requires=clipboard-server.service
PartOf=graphical-session.target

[Service]
ExecStart=$out/bin/clipboard-client
Type=exec
PrivateTmp=yes
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
EOF
  '';

  meta = {
    description = "Iced clipboard manager client";
    mainProgram = "clipboard-client";
  };
})
