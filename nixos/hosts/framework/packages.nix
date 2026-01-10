{ config, pkgs, inputs, ... }:

{
  programs.hyprland.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
    dotbot
    ghostty
    kitty
    fish
    brave
    spotify
    code-cursor
    bitwarden-desktop
    starship
    quickshell
    obsidian
    inputs.opencode-flake.packages.${pkgs.system}.default
    brightnessctl
    eza
    yazi
    gcc
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    tree-sitter
  ];
}

