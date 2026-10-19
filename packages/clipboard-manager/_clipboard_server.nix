{
  lib,
  rustPlatform,
  pkg-config,
  wayland,
}:
rustPlatform.buildRustPackage rec {
  pname = "clipboard-server";
  version = "0.1.0";

  src = ./server;

  # Requires ./server/Cargo.lock to be committed to the repo.
  # If you prefer not to commit it, delete this line and set:
  #   cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # then run `nix build` and paste the "got" hash back in.
  cargoLock.lockFile = ./server/Cargo.lock;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    # wayland-client (pulled in by wl-clipboard-rs) links libwayland-client.so
    # on the "client_system" backend, which is the default for wayland-client
    # 0.31+. Putting it here sets rpath so the binary runs from the store.
    wayland
  ];

  env.LC_ALL = "C.UTF-8";

  # No tests defined in the crate — skip the check phase instead of letting
  # cargo spin up an empty test runner.
  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/systemd/user
    # WARN: DO NOT DROP graphical-session! The server needs WAYLAND_DISPLAY
    # set by the compositor, and it speaks the Wayland protocol directly via
    # wl-clipboard-rs (no external wl-copy/wl-paste binaries are invoked).
    # A cli should read ~/.cache/clipboard-manager/history.json
    cat > $out/share/systemd/user/clipboard-server.service <<EOF
[Unit]
Description=clipboard-server
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=$out/bin/clipboard-server
Type=exec
PrivateTmp=yes
Restart=on-failure
RestartSec=1

[Install]
WantedBy=graphical-session.target
EOF
  '';

  meta = {
    description = "clipboard manager server";
    mainProgram = "clipboard-server";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
