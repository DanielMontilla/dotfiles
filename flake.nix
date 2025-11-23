{
  description = "Daniel's Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, nixgl }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        # overlays = [ nixgl.overlay ];
      };
      my-packages = [
        # System
        pkgs.git
        pkgs.dotbot
        pkgs.glibcLocales 

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
        # pkgs.ghostty
        # (pkgs.writeShellScriptBin "ghostty" ''
        #   exec ${(pkgs.nixgl.nvidiaPackages { version = "580.82.09"; sha256 = null; }).nixGLNvidia}/bin/nixGLNvidia ${pkgs.ghostty}/bin/ghostty "$@"
        # '')

        # Hyprland
        pkgs.wayland
        pkgs.quickshell
        # pkgs.waybar
      ];
    in {
      packages.${system}.default = pkgs.buildEnv {
        name = "home";
        paths = my-packages;
      };
    };
}
