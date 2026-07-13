{ config, pkgs, inputs, ... }:

{

  # Mutable Programs
  programs.nix-ld.enable = true;

  services.envfs.enable = true;

  # Niri compositor
  programs.niri = {
    enable = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.upower.enable = true;

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };

  environment.localBinInPath = true;
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    neovim
    dotbot
    alacritty
    brave
    wofi
    brightnessctl
    playerctl
    fish
    starship
    wl-clipboard
    eza
    fastfetch
    btop
    curl
    ripgrep
    inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.fish.enable = true;
}
