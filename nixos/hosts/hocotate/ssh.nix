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

  users.users.daniel.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+ZZJOYG8B7Rn5ZQdBAXsBgBQygJ7Vk6zlTfogMwyJ daniel@olimar"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/nUf7c2Sekdov5CZspz7GslJacskM2MA8mrnwKdbhO daniel@louie"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPRA9twrCHL///CFOBc0ZYqKFIpQVaPjUflyHVaCZnni daniel@oatchi"
  ];

  services.tailscale.enable = true;

  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  networking.firewall.checkReversePath = "loose";
}
