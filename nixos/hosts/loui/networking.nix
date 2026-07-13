{ config, pkgs, ... }:

{
  networking.hostName = "loui";
  networking.networkmanager.enable = true;
}
