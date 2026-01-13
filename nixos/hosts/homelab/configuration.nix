{ config, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./networking.nix
    ./user.nix
    ./packages.nix
  ];

  system.stateVersion = "25.05";
}
