{
  config,
  pkgs,
  lib,
  ...
}:

let
  # INFRASTRUCTURE WireGuard tunnels -> NetworkManager connections.
  # Only tunnels the system depends on live here (fixed ports, inbound peers,
  # custom policy routing). Provider VPNs (Surfshark etc.) are NOT declared —
  # import them at runtime with wlctl; see wiki/vpn.md.
  #
  # Private keys live in /home/daniel/vpn/<name>.key (NEVER in git or nix store).
  # Profiles are seeded at activation time, start OFF, and are toggled in wlctl.
  #
  # Fields:
  #   address       required  CIDR assigned to the tunnel interface
  #   peerPublicKey required  server's wireguard public key
  #   endpoint      required  host:port of the peer
  #   allowedIPs    required  list of CIDRs routed into the tunnel
  #   listenPort    optional  fixed local UDP port (also opened in firewall)
  #   keepalive     optional  persistent-keepalive seconds (default 25)
  #   dns           optional  list of DNS servers pushed onto this link
  #   routeTable    optional  policy-routing table number: routes+rule go there
  #                           instead of main (used when tunnel must NOT grab
  #                           the machine's default route)
  vpns = { };

  vpnNames = lib.attrNames vpns;

  mkVpnBlock = name: v:
    let
      keyFile = "/home/daniel/vpn/${name}.key";
      ip = lib.head (lib.splitString "/" v.address);
      listenPortLine =
        if v ? listenPort then "\nlisten-port=${toString v.listenPort}" else "";
      keepalive = v.keepalive or 25;
      dnsLine =
        if v ? dns then "\ndns=${lib.concatStringsSep "," v.dns}" else "";
      policyLines =
        if v ? routeTable then ''
          # Policy routing: keep NM routes out of the main table
          route-table=${toString v.routeTable}
          routing-rule1=priority 100 from ${ip} table ${toString v.routeTable}
        '' else
          "";
    in ''
      if [ -f ${keyFile} ]; then
        key=$(tr -d ' \n' < ${keyFile})
        cat > /etc/NetworkManager/system-connections/${name}.nmconnection <<EOF
      [connection]
      id=${name}
      type=wireguard
      interface-name=${name}
      # Start OFF; toggle in wlctl
      autoconnect=false

      [wireguard]
      private-key=$key${listenPortLine}

      [wireguard-peer.${v.peerPublicKey}]
      endpoint=${v.endpoint}
      allowed-ips=${lib.concatStringsSep "," v.allowedIPs}
      persistent-keepalive=${toString keepalive}

      [ipv4]
      method=manual
      address1=${v.address}${dnsLine}
      ${policyLines}EOF
        chmod 600 /etc/NetworkManager/system-connections/${name}.nmconnection
      else
        echo "wlctl-vpns: skipping ${name}, missing ${keyFile}" >&2
      fi
    '';
in

{
  networking.hostName = "louie";
  networking.networkmanager.enable = true;

  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  # Seed one NetworkManager profile per entry in `vpns`.
  # Keys are read from disk at activation time so they never enter the store.
  # NOTE: removing an entry does NOT delete its profile —
  # sudo rm /etc/NetworkManager/system-connections/<name>.nmconnection
  system.activationScripts.wgNmConnections.text = ''
    mkdir -p /etc/NetworkManager/system-connections
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkVpnBlock vpns)}
  '';

  # Loose reverse-path filter on tunnel interfaces (wg-quick used to do this)
  environment.etc."NetworkManager/dispatcher.d/10-wg-vpns-rpfilter" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      [ "$2" = "up" ] || exit 0
      ${lib.concatMapStrings (name: ''
        if [ "$1" = "${name}" ]; then
          ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.${name}.rp_filter=2 > /dev/null
        fi
      '') vpnNames}    '';
  };

  networking.firewall.allowedUDPPorts =
    lib.filter (p: p != null) (lib.mapAttrsToList (_: v: v.listenPort or null) vpns);
  networking.firewall.trustedInterfaces = vpnNames;
}