{ config, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.daniel.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8OTlg/sl4xMJJZUJBEgFv6cJi3r2NMoATgIiLvdf9+ daniel@louie"
  ];
}
