{ config, pkgs, ... }:

{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.14.0.2/16" ];
    listenPort = 51820;
    privateKeyFile = "/etc/nixos/secrets/surfshark.key";
    table = "off";

    postUp = let
      ip = "${pkgs.iproute2}/bin/ip";
      sysctl = "${pkgs.procps}/bin/sysctl";
    in ''
      ${ip} route add default dev wg0 table 51820
      ${ip} rule add from 10.14.0.2 table 51820 priority 100
      ${sysctl} -w net.ipv4.conf.wg0.rp_filter=2
    '';

    preDown = let ip = "${pkgs.iproute2}/bin/ip"; in ''
      ${ip} rule del from 10.14.0.2 table 51820 priority 100
      ${ip} route del default dev wg0 table 51820
    '';

    peers = [
      {
        publicKey = "lLqqxZuCTtIpBjgZJYWzPQn/7st24iVpJN+/xS7jogs=";
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "co-bog.prod.surfshark.com:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.trustedInterfaces = [ "wg0" ];
}

