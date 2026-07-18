{ config, pkgs, inputs, ... }:

{

  # Mutable Programs
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    wayland
    libglvnd
    mesa
    libdrm
    libxkbcommon
    fontconfig
    freetype
    vulkan-loader
  ];

  services.envfs.enable = true;

  services.flatpak = {
    enable = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    ];
    packages = [
      "com.usebruno.Bruno"
    ];
  };

  # Niri compositor
  programs.niri = {
    enable = true;
  };

  # Docker virtualization
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.upower.enable = true;

  # DDC/CI monitor brightness/contrast control (external/desktop displays)
  boot.kernelModules = [ "i2c_dev" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="users", MODE="0660"
  '';

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
    XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/share/X11/xkb";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    bibata-cursors
    neovim
    dotbot
    alacritty
    gnome-keyring
    brave
    wofi
    brightnessctl
    ddcutil
    playerctl
    fish
    starship
    quickshell
    wl-clipboard
    eza
    fastfetch
    btop
    curl
    ripgrep
    inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    oxker
  ];

  programs.fish.enable = true;
}
