{ config, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 60d";
  };

  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./greeter.nix
    ./networking.nix
    ./user.nix
    ./packages.nix
  ];

  system.stateVersion = "25.05";
}
