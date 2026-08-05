{ config, pkgs, ... }:

let
  superseedr = pkgs.stdenv.mkDerivation {
    pname = "superseedr";
    version = "1.0.12";
    src = pkgs.fetchurl {
      url = "https://github.com/Jagalite/superseedr/releases/download/v1.0.12/superseedr_v1.0.12_linux-amd64.tar.gz";
      sha256 = "0e5e17f58ca7037dcb0efe865f90d326ce8d106ec64b49919dd0c53f66a4abd2";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.openssl pkgs.libgcc ];
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      cp superseedr_v1.0.12_linux-amd64/superseedr $out/bin/superseedr
      chmod +x $out/bin/superseedr
    '';
  };

  # Isolated network namespace routing torrent traffic through the wg-co-bog tunnel.
  netns = "torrent";
  vethHost = "ss-host";
  vethNetns = "ss-ns";
  cleanNetns = "10.200.9.0/30";
  hostIp = "10.200.9.1";
  netnsIp = "10.200.9.2";
  vpnIp = "10.14.0.2";
  vpnTable = "51820";
in
{
  environment.systemPackages = [
    superseedr
    (pkgs.writeShellScriptBin "superseedr-tui" ''
      IP=${pkgs.iproute2}/bin/ip
      IPTABLES=${pkgs.iptables}/bin/iptables
      SUDO=sudo
      SUPERSEEDR=${superseedr}/bin/superseedr

      set -e
      CREATED=0
      if ! $SUDO $IP netns list | grep -qw ${netns}; then
        $SUDO $IP netns add ${netns}
        $SUDO $IP link add ${vethHost} type veth peer name ${vethNetns}
        $SUDO $IP link set ${vethNetns} netns ${netns}
        $SUDO $IP link set ${vethHost} up
        $SUDO $IP addr add ${hostIp}/30 dev ${vethHost}
        $SUDO $IP netns exec ${netns} $IP link set lo up
        $SUDO $IP netns exec ${netns} $IP link set ${vethNetns} up
        $SUDO $IP netns exec ${netns} $IP addr add ${netnsIp}/30 dev ${vethNetns}
        $SUDO $IP netns exec ${netns} $IP route add default via ${hostIp}
        $SUDO $IP rule add from ${cleanNetns} table ${vpnTable} priority 200 2>/dev/null || true
        if ! $SUDO $IPTABLES -t nat -C POSTROUTING -s ${cleanNetns} -j SNAT --to-source ${vpnIp} 2>/dev/null; then
          $SUDO $IPTABLES -t nat -A POSTROUTING -s ${cleanNetns} -j SNAT --to-source ${vpnIp}
        fi
        $SUDO ${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1 >/dev/null
        CREATED=1
      fi

      set +e
      $SUDO $IP netns exec ${netns} $SUDO -u daniel $SUPERSEEDR
      EXIT=$?
      set -e

      if [ "$CREATED" = 1 ]; then
        $SUDO $IP rule del from ${cleanNetns} table ${vpnTable} priority 200 2>/dev/null || true
        $SUDO $IPTABLES -t nat -D POSTROUTING -s ${cleanNetns} -j SNAT --to-source ${vpnIp} 2>/dev/null || true
        $SUDO $IP link del ${vethHost} 2>/dev/null || true
        $SUDO $IP netns del ${netns} 2>/dev/null || true
      fi

      exit $EXIT
    '')
  ];

  # Allow forwarding between the netns veth and the WireGuard tunnel.
  networking.firewall.trustedInterfaces = [ vethHost ];
}