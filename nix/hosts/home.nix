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
    ./../packages/dotbot.nix

  ];

  networking = {
    hostName = "home";
    useDHCP = true;
  };

  time = {
    timeZone = "America/Caracas";
  };


  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  users.users = {
    daniel = {
      isNormalUser = true;
      createHome = false;
      initialPassword = "nixos";
      extraGroups = [ "wheel" "networkmanager" "sudo" ];
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  system.stateVersion = "24.11";
}
