{ flake.nixosModules.virtualisation_containers = { ... }: {
  virtualisation.podman = {
    # INFO: podman is enabled in home manager too
    # It's needed globally to enable better docker compatibility,
    # such as managing the socket /var/run/docker.sock
    enable       = true; # this is also in home-manager
    dockerCompat = true;
    };
};

flake.homeModules.virtualisation_containers = { pkgs, ... }: {
  services.podman.enable = true;
  home.packages = [ pkgs.podman-desktop ];

  services.podman.settings.registries.search = [
    "docker.io"
    "quay.io"
    "ghcr.io"
    ];
};}
