{ config, pkgs, ... }:

{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # OpenVPN support for NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];
}

