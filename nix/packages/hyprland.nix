# https://wiki.hyprland.org/Nix/
# https://mynixos.com/nixpkgs/options/programs.hyprland
{ config, pkgs, ... }:

{

	environment.systemPackages = [ pkgs.kitty pkgs.wofi ];

	programs.hyprland = {
		enable = true;
		withUWSM = true;
	};

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  hardware = {
    nvidia.modesetting.enable = true;
  };
}
