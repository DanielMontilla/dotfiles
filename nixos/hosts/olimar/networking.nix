{ config, pkgs, ... }:

{
  networking.hostName = "olimar";
  networking.networkmanager.enable = true;

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  networking.wireguard.interfaces = {
    wg-co-bog = {
      privateKeyFile = "/var/lib/wireguard/wg-co-bog.key";
      listenPort = 51820;
      ips = [ "10.14.0.2/16" ];

      peers = [
        {
          publicKey = "lLqqxZuCTtIpBjgZJYWzPQn/7st24iVpJN+/xS7jogs=";
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = "co-bog.prod.surfshark.com:51820";
          persistentKeepalive = 25;
        }
      ];

      allowedIPsAsRoutes = false;

      postSetup = ''
        ${pkgs.iproute2}/bin/ip route add default dev wg-co-bog table 51820
        ${pkgs.iproute2}/bin/ip rule add from 10.14.0.2 table 51820 priority 100
        ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.wg-co-bog.rp_filter=2
      '';

      preShutdown = ''
        ${pkgs.iproute2}/bin/ip rule del from 10.14.0.2 table 51820 priority 100
        ${pkgs.iproute2}/bin/ip route del default dev wg-co-bog table 51820
      '';
    };
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      bind-address-ipv4 = "10.14.0.2";
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist = "127.0.0.1";
    };
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.firewall.trustedInterfaces = [ "wg-co-bog" ];
}
