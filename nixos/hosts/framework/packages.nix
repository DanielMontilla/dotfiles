{ config, pkgs, inputs, ... }:

{
  programs.hyprland.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.upower.enable = true;

  virtualisation.docker.enable = true;

  # TODO: move to own "theme" file
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    dotbot
    ghostty
    kitty
    fish
    brave
    firefox
    spotify
    code-cursor
    bitwarden-desktop
    starship
    quickshell
    wofi
    obsidian
    inputs.opencode-flake.packages.${pkgs.system}.default
    brightnessctl
    eza
    yazi
    gcc
    slack
    lazygit
    zellij
    networkmanagerapplet
    bruno
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    tree-sitter
  ];
}

