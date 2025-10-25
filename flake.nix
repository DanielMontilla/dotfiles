{
  description = "Daniel's Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      my-packages = [
        # System
        pkgs.git
        pkgs.dotbot

        # Fonts
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.iosevka
        pkgs.nerd-fonts.fira-code

        # Terminal
        pkgs.neovim
        pkgs.starship
        pkgs.fish

        # Apps
        pkgs.firefox
        pkgs.bitwarden
        pkgs.spotify
        pkgs.discord
        pkgs.brave
        pkgs.code-cursor
        pkgs.slack

        # Hyprland
        pkgs.wayland
        pkgs.waybar
      ];
    in {
      packages.${system}.default = pkgs.buildEnv {
        name = "home";
        paths = my-packages;
      };
    };
}
