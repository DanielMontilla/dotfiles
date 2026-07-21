{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 2222 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      Port = 2222;
    };
  };

  # olimar trusts peer keys (per-machine: only peer public keys go here)
  users.users.daniel.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/nUf7c2Sekdov5CZspz7GslJacskM2MA8mrnwKdbhO daniel@louie"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPRA9twrCHL///CFOBc0ZYqKFIpQVaPjUflyHVaCZnni daniel@oatchi"
  ];

  # Tailscale mesh VPN for internet reachability (free personal plan)
  services.tailscale.enable = true;

  # Tailscale firewall: allow Tailscale UDP port and use loose reverse-path
  # to prevent packet drops on multi-homed setups and enable direct P2P.
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  networking.firewall.checkReversePath = "loose";
}
