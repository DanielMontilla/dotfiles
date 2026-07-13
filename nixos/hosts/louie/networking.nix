{ config, pkgs, ... }:

{
  networking.hostName = "louie";
  networking.networkmanager.enable = true;
}
