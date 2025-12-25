{ config, pkgs, ... }:

{
  services.sysc-greet = {
    enable = true;
    compositor = "hyprland";
  };
}

