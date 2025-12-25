{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
