{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./networking.nix
    ./user.nix
    ./packages.nix
    ./fonts.nix
    ./graphics.nix
    ./ssh.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Unlock gnome-keyring at TTY login using the login password, so it acts as
  # the system secret service (no more Brave/Chromium keyring password prompts).
  security.pam.services.login.enableGnomeKeyring = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = "25.05";
}
