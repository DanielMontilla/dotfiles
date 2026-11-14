{ config, lib, pkgs, unstable, ... }:

let
  # `whoami` on the Mac. nix-darwin checks at activation that this account
  # exists (`id -- "$primaryUser"`), and it is used for Homebrew's ownership
  # and for per-user `defaults write`.
  user = "danielmontilla";
in
{
  # Set once on a new machine; do not bump it later (see `darwin-rebuild changelog`).
  system.stateVersion = 7;

  # Required by the Homebrew module and by user-scoped defaults.
  system.primaryUser = user;

  # The Tailscale device name comes from the OS hostname, and MagicDNS derives
  # <device>.<tailnet>.ts.net from it. Set all three so a fresh install registers
  # as pikpik without renaming by hand in the admin console, and so
  # pikpik.local works on the local network. localHostName defaults to hostName.
  networking.hostName = "pikpik";
  networking.computerName = "pikpik";

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "claude-code" ];

  # --------------------------------------------------------------- packages
  # CLI tools only. GUI apps come from Homebrew casks (see `homebrew` below):
  # a cask lands in /Applications with a stable Developer ID signature, so
  # Accessibility/Network-Extension grants survive updates, and the app can
  # update itself.
  environment.systemPackages = import ./packages.nix { inherit pkgs unstable; };

  programs.fish.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fish.interactiveShellInit = ''
    direnv hook fish | source
  '';
  environment.shells = [ pkgs.fish ];

  # -------------------------------------------------------------------- nix
  # nix-darwin owns /etc/nix/nix.conf now — this replaces
  # `scripts/enable-nix-features` (which is only needed to bootstrap).
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@admin" ];
    # Known to corrupt the store; `nix.optimise.automatic` below is the
    # supported way to deduplicate.
    auto-optimise-store = false;
  };

  nix.channel.enable = false;

  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; Hour = 3; Minute = 15; };
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;

  # -------------------------------------------------------------------- ssh
  # Replaces `sudo systemsetup -setremotelogin on`. Key-only, and the allowed
  # keys are declared below rather than appended to ~/.ssh/authorized_keys.
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
    '';
  };

  # Keys allowed to log in as this account (README §10). nix-darwin writes them
  # to /etc/ssh/nix_authorized_keys.d/<user> and reads that through
  # `AuthorizedKeysCommand`, in addition to the usual ~/.ssh/authorized_keys —
  # so a pre-existing file on a work Mac keeps working, and nothing is appended
  # by hand. These are the same keys olimar/louie use on the mesh.
  users.users.${user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+ZZJOYG8B7Rn5ZQdBAXsBgBQygJ7Vk6zlTfogMwyJ daniel@olimar"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/nUf7c2Sekdov5CZspz7GslJacskM2MA8mrnwKdbhO daniel@louie"
    # oatchi (Linux). Fingerprint: SHA256:aM0msWCwmJj5gTUXTHat7cDlGG4zcyomkrdAqQONvuw
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPRA9twrCHL///CFOBc0ZYqKFIpQVaPjUflyHVaCZnni daniel@oatchi"
  ];

  # --------------------------------------------------------------- homebrew
  homebrew = {
    enable = true;

    # Zed, Ghostty, and Tailscale all self-update (`auto_updates: true` in
    # their casks), so Homebrew skips them unless `greedy` is set. That is why
    # `upgrade` stays off: `darwin-rebuild switch` remains idempotent, and the
    # apps keep themselves current. The Tailscale cask was renamed from
    # `tailscale` to `tailscale-app`; the old token still resolves but warns.
    onActivation = {
      autoUpdate = true;
      upgrade = false;
      # NOT "zap": the Zed cask would delete ~/.config/zed, and Ghostty's would
      # delete ~/Library/Application Support/com.mitchellh.ghostty, which is
      # where the linked config lives.
      cleanup = "none";
    };

    casks = [ "ghostty" "zed" "tailscale-app" "karabiner-elements" ];
    enableFishIntegration = true;
  };

  # --------------------------------------------------------------- defaults
  # Only what is worth declaring. Add more as you notice yourself clicking the
  # same checkbox twice; anything not covered here can go in
  # system.defaults.CustomUserPreferences.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
    };

    dock = {
      autohide = true;
      tilesize = 48;
      show-recents = false;
      mru-spaces = false;
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
      _FXSortFoldersFirst = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    screencapture.location = "~/Pictures/Screenshots";

  };

  # Touch ID for sudo, with the password as fallback.
  security.pam.services.sudo_local.touchIdAuth = true;
}
