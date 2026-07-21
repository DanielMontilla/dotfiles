{ config, pkgs, ... }:

{
  networking.hostName = "hocotate";
  networking.networkmanager.enable = true;
}
