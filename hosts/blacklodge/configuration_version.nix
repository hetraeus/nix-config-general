{ flake.nixosModules.blacklodgeModules = { ... }: {
# WARN: READ THE COMMENT BLOCK!

# First version of NixOS you have installed on this particular machine
# Used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
#
# Most users should NEVER change this value after the initial install
# FOR ANY REASON, even if you've upgraded your system to a new NixOS release.
#
# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
# so changing it will NOT upgrade your system.
# To actually upgrade the system, check:
# https://nixos.org/manual/nixos/stable/#sec-upgrading
#
# This value being lower than the current NixOS release
# does NOT mean your system is out of date, out of support, or vulnerable.
#
# Do NOT change this value unless you have manually inspected
# all the changes it would make to your configuration and migrated your data accordingly.
#
# INFO
# man configuration.nix
# https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion

system.stateVersion = "24.05";
};}
