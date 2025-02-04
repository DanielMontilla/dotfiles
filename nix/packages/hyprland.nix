# https://wiki.hyprland.org/Nix/
# https://mynixos.com/nixpkgs/options/programs.hyprland
{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.hyprland ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  hardware = {
    nvidia.modesetting.enable = true;
  };
}