{ flake.nixosModules.desktop_troubleshoot = { pkgs, ... }: {
  environment.systemPackages = [
    pkgs.vulkan-tools
    pkgs.wayland-utils
    ];
};}
