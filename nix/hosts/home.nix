{ self, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./common.nix

    ./../packages/git.nix
    ./../packages/neovim.nix
    ./../packages/vscode.nix
    ./../packages/firefox.nix
    ./../packages/spotify.nix
    ./../packages/hyprland.nix
    ./../packages/bitwarden.nix
  ];

  networking = {
    hostName = "home";
    useDHCP = true;
  };

  time = {
    timeZone = "America/Caracas";
    hardwareClock = "UTC";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8" ];
  };

  users.users = {
    mutableUsers = true;
    daniel = {
      isNormalUser = true;
      createHome = false;
      home = "/home";
      shell = pkgs.bash;
      initialPassword = "nixos";
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}
