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

  # louie trusts olimar's key (per-machine: only peer public keys go here)
  users.users.daniel.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+ZZJOYG8B7Rn5ZQdBAXsBgBQygJ7Vk6zlTfogMwyJ daniel@olimar"
  ];

  # Tailscale mesh VPN for internet reachability (free personal plan)
  services.tailscale.enable = true;
}
