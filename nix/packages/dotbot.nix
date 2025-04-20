{ config, pkgs, ... }:

{
	environment.systemPackages = [ pkgs.dotbot ];
}
