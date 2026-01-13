{ config, pkgs, ... }:

{
  networking.hostName = "homelab";
  networking.networkmanager.enable = true;
}
