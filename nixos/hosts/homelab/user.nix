{ config, pkgs, ... }:

{
  time.timeZone = "America/Caracas";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.daniel = {
    isNormalUser = true;
    description = "Daniel Montilla";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}
