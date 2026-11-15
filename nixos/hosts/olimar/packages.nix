{ config, pkgs, inputs, ... }:

{

  # Mutable Programs
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # C/C++ runtime + compression/crypto (also needed by Zed-downloaded LSP servers)
    stdenv.cc.cc.lib
    zlib
    zstd
    openssl
    curl
    # D-Bus / GNOME stack: libgio-2.0.so.0 lives here (fixes `zed .` exit 127)
    glib
    dbus
    gdk-pixbuf
    libsecret
    # Audio / graphics / Wayland (manually-installed Zed via https://zed.dev/install.sh)
    alsa-lib
    wayland
    libglvnd
    mesa
    libdrm
    libxkbcommon
    fontconfig
    freetype
    vulkan-loader
    vulkan-validation-layers
    xorg.libX11
    xorg.libxcb
    xorg.libXext
    # Zed build inputs that its runtime/dlopen can expect
    sqlite
    libgit2
  ];

  services.envfs.enable = true;

  services.flatpak = {
    enable = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
      { name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
    ];
    packages = [
      "com.usebruno.Bruno"
    ];
  };

  # Mosh mobile shell (auto-opens UDP 60000-61000 in firewall)
  programs.mosh.enable = true;

  # Niri compositor
  programs.niri = {
    enable = true;
  };

  # Docker virtualization
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.upower.enable = true;

  # DDC/CI monitor brightness/contrast control (external/desktop displays)
  boot.kernelModules = [ "i2c_dev" ];
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="users", MODE="0660"

    # sysfs attribute files under /sys/class/leds have no devnode, so GROUP/MODE
    # keys do not apply to them. Grant group-write via RUN=+ chmod/chgrp (the
    # NixOS udev rules builder requires absolute store paths for RUN programs).
    SUBSYSTEM=="leds", KERNEL=="chromeos::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chgrp users /sys/class/leds/chromeos::kbd_backlight/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/chromeos::kbd_backlight/brightness"
    SUBSYSTEM=="leds", KERNEL=="chromeos:white:power", RUN+="${pkgs.coreutils}/bin/chgrp users /sys/class/leds/chromeos:white:power/brightness /sys/class/leds/chromeos:white:power/trigger", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/chromeos:white:power/brightness /sys/class/leds/chromeos:white:power/trigger"
  '';

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
    };
  };

  environment.localBinInPath = true;
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    NIXOS_OZONE_WL = "1";
    XKB_CONFIG_ROOT = "${pkgs.xkeyboard_config}/share/X11/xkb";
    # Playwright: use the Nix-built browsers (version-matched to playwright-driver) instead of downloading
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    bibata-cursors
    neovim
    dotbot
    alacritty
    gnome-keyring
    libnotify
    brave
    wofi
    brightnessctl
    ddcutil
    playerctl
    fish
    starship
    quickshell
    wl-clipboard
    wtype
    evtest
    eza
    fastfetch
    btop
    curl
    ripgrep
    inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.handy
    nodejs_24
    oxker
    gammastep
    lm_sensors
    snixembed
    mpv
    obs-studio
    direnv
    wireguard-tools
    inputs.wlctl.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Agent computer-use: frame/audio extraction from video, full-desktop screen recording
    ffmpeg
    wf-recorder

    # Agent computer-use: headless Chromium driven by chrome-devtools-mcp
    # Pins a stable /run/current-system/sw/bin/chromium path (nix store paths move)
    chromium

    # Video transcription: yt-dlp downloads audio/captions, Whisper transcribes locally
    # (ffmpeg above is required by both). Exposes `whisper` on PATH.
    # Unstable: the 25.11 pin's yt-dlp gets HTTP 403 from YouTube
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.yt-dlp
    (python3.withPackages (ps: [ ps.openai-whisper ]))

    # `yt-transcribe <url>`: source lives in ~/dotfiles/tools/yt-transcribe (Bun + Effect).
    # Installs its node_modules on first run from the committed bun.lock.
    (writeShellScriptBin "yt-transcribe" ''
      dir="$HOME/dotfiles/tools/yt-transcribe"
      if [ ! -d "$dir/node_modules" ]; then
        (cd "$dir" && ${bun}/bin/bun install --frozen-lockfile)
      fi
      exec ${bun}/bin/bun run "$dir/src/main.ts" "$@"
    '')
  ];

  programs.fish.enable = true;
}
