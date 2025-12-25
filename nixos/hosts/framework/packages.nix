{ config, pkgs, ... }:

{
  programs.hyprland.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
    dotbot
    ghostty
    wofi
    fish
    brave
    spotify
    code-cursor
    bitwarden-desktop
    starship
    quickshell
    obsidian
    opencode
    brightnessctl
    eza
  ];
}

