{ config, pkgs, inputs, ... }:

let
  cursor-src = pkgs.fetchurl {
    url = "https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/2.5";
    sha256 = "csvj0THOX/RPi7Docv033mi8DlEOEdnjFIQ8jL7HPO8=";
  };
  cursor-appimage = pkgs.writeScriptBin "cursor" ''
    #!${pkgs.runtimeShell}
    nohup ${pkgs.appimage-run}/bin/appimage-run ${cursor-src} "$@" </dev/null >/dev/null 2>&1 &
  '';
in

{
  services.flatpak = {
    enable = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    ];
    packages = [
      "com.usebruno.Bruno"
      "org.pgadmin.pgadmin4"
    ];
  };

  # Niri compositor
  programs.niri = {
    enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  services.cloudflared = {
    enable = true;
    tunnels = {
      "06101592-5b5b-4d9a-a00a-7db47d0ca40e" = {
        credentialsFile = "/var/lib/cloudflared/tunnel-creds.json";
        ingress = {
          "montilla.pagoasap.com" = "http://localhost:4318";
        };
        default = "http_status:404";
      };
    };
  };

  services.upower.enable = true;

  virtualisation.docker.enable = true;

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.localBinInPath = true;
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    zed-editor
    dotbot
    ghostty
    alacritty
    kitty
    wl-clipboard
    fish
    brave
    firefox
    spotify
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
    fastfetch
    lm_sensors
    gammastep
    qbittorrent
    vlc
    cursor-appimage
    glances
    btop
    xdg-desktop-portal-gnome
  ];

  programs.fish.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    tree-sitter
  ];
}