{
  description = "pikpik — macOS work profile (user packages)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      # Apple Silicon. Intel Macs: change to "x86_64-darwin".
      system = "aarch64-darwin";

      # Claude Code is unfree; allow only it, not everything.
      allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };
      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };

      # --- Prebuilt vendor apps ------------------------------------------------
      # These are the same artifacts their curl installers download. Packaging
      # the release instead of building from source keeps `scripts/install`
      # fast on Darwin, where nixpkgs has no official binary cache.
      #
      # Update a version, blank its hashes, then:
      #   nix build path:profiles/pikpik/nixos#zed   (or #codex, #ghostty)
      # and paste the hashes from the error, or prefetch:
      #   nix store prefetch-file --json <url>

      # Zed
      zedVersion = "1.27.0";
      zedArch = if system == "aarch64-darwin" then "aarch64" else "x86_64";
      zedHash =
        if system == "aarch64-darwin"
        then "sha256-jc/fqpSRfOzg/1Krbj9xF8Zke3jzLSZmhM8ME0Ytdqg="
        else "sha256-eomp1AQBAEMp7EDvDxiO5VNuY4kGsf9uW/x57afJlbM=";

      zedApp = pkgs.stdenv.mkDerivation {
        pname = "zed";
        version = zedVersion;

        src = pkgs.fetchurl {
          url = "https://github.com/zed-industries/zed/releases/download/v${zedVersion}/Zed-${zedArch}.dmg";
          hash = zedHash;
        };

        # The undmg setup hook unpacks .dmg sources in unpackPhase.
        nativeBuildInputs = [ pkgs.undmg ];
        sourceRoot = ".";

        installPhase = ''
          runHook preInstall

          mkdir -p $out/Applications $out/bin
          cp -R "Zed.app" "$out/Applications/Zed.app"

          # `zeditor` keeps the shared fish `zed` function working; `zed` is
          # the normal CLI name (and matches the vendor installer).
          ln -s "$out/Applications/Zed.app/Contents/MacOS/cli" $out/bin/zed
          ln -s "$out/Applications/Zed.app/Contents/MacOS/cli" $out/bin/zeditor

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Zed editor (official prebuilt macOS app)";
          homepage = "https://zed.dev";
          license = licenses.gpl3Only;
          sourceProvenance = [ sourceTypes.binaryNativeCode ];
          platforms = [ "aarch64-darwin" "x86_64-darwin" ];
          mainProgram = "zed";
        };
      };

      # Ghostty
      # The Ghostty flake can't build on Darwin (it needs Swift 6/xcodebuild,
      # which nixpkgs doesn't provide), and its .dmg is APFS, which `undmg`
      # can't read. The official universal .zip is the right artifact: one
      # hash for both Apple Silicon and Intel.
      ghosttyVersion = "1.4.0";
      ghosttyHash = "sha256-7Mno3t6oixmqG+Ib5M9X3WDRd5q1OC1eYHC9atfQtUA=";

      ghosttyApp = pkgs.stdenv.mkDerivation {
        pname = "ghostty";
        version = ghosttyVersion;

        src = pkgs.fetchurl {
          url = "https://release.files.ghostty.org/${ghosttyVersion}/ghostty-macos-universal.zip";
          hash = ghosttyHash;
        };

        nativeBuildInputs = [ pkgs.unzip ];
        unpackPhase = "unzip -q $src";
        sourceRoot = ".";

        installPhase = ''
          runHook preInstall

          mkdir -p $out/Applications $out/bin
          cp -R "Ghostty.app" "$out/Applications/Ghostty.app"
          ln -s "$out/Applications/Ghostty.app/Contents/MacOS/ghostty" $out/bin/ghostty

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Ghostty terminal (official prebuilt universal macOS app)";
          homepage = "https://ghostty.org";
          license = licenses.mit;
          sourceProvenance = [ sourceTypes.binaryNativeCode ];
          platforms = [ "aarch64-darwin" "x86_64-darwin" ];
          mainProgram = "ghostty";
        };
      };

      # OpenAI Codex CLI
      codexVersion = "0.167.0";
      codexArch = if system == "aarch64-darwin" then "aarch64" else "x86_64";
      codexHash =
        if system == "aarch64-darwin"
        then "sha256-r0XtRdlA15mICWIsHAKW0wmO19f61pUoRCLCKL1FRRc="
        else "sha256-PXxMgylttjtRCOE2Esd/PlAgtsXy/ABL7kE6XMkt6Jk=";

      codexApp = pkgs.stdenv.mkDerivation {
        pname = "codex";
        version = codexVersion;

        src = pkgs.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${codexVersion}/codex-package-${codexArch}-apple-darwin.tar.gz";
          hash = codexHash;
        };

        dontUnpack = true;

        installPhase = ''
          runHook preInstall

          # Keep the vendor package layout intact: codex resolves its bundled
          # resources/helpers relative to its own directory.
          mkdir -p $out/libexec/codex $out/bin
          tar -xzf "$src" -C $out/libexec/codex

          for b in codex codex-code-mode-host codex-exec-server; do
            if [ -x "$out/libexec/codex/bin/$b" ]; then
              ln -s "$out/libexec/codex/bin/$b" "$out/bin/$b"
            fi
          done

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "OpenAI Codex CLI (official prebuilt macOS binary)";
          homepage = "https://github.com/openai/codex";
          license = licenses.asl20;
          sourceProvenance = [ sourceTypes.binaryNativeCode ];
          platforms = [ "aarch64-darwin" "x86_64-darwin" ];
          mainProgram = "codex";
        };
      };

      # Claude Code ships prebuilt. Unstable no longer lists x86_64-darwin, so
      # Intel Macs fall back to the stable channel's package.
      claudeCode =
        if system == "aarch64-darwin"
        then pkgsUnstable.claude-code
        else pkgs.claude-code;

      # Herdr
      # nixpkgs-unstable's package is the latest release and is already in the
      # official binary cache for aarch64-darwin (integration assets included).
      # Unstable dropped x86_64-darwin entirely, so Intel uses the upstream
      # prebuilt binary — the same one herdr.dev/install.sh downloads.
      herdrVersion = "0.9.5";
      herdrPkg =
        if system == "aarch64-darwin"
        then pkgsUnstable.herdr
        else
          pkgs.stdenv.mkDerivation {
            pname = "herdr";
            version = herdrVersion;

            src = pkgs.fetchurl {
              url = "https://github.com/herdrdev/herdr/releases/download/v${herdrVersion}/herdr-macos-x86_64";
              hash = "sha256-X7CpCOx/Z0Xj4kVziwa/rVbEY5HDkas8CVX76tAfE2k=";
            };

            dontUnpack = true;

            installPhase = ''
              runHook preInstall
              install -Dm755 "$src" $out/bin/herdr
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Agent multiplexer that lives in your terminal (prebuilt macOS binary)";
              homepage = "https://herdr.dev";
              license = licenses.asl20;
              sourceProvenance = [ sourceTypes.binaryNativeCode ];
              platforms = [ "x86_64-darwin" ];
              mainProgram = "herdr";
            };
          };

      # Keep in sync with devShells below.
      #
      # Deliberately NOT included:
      #   openssh — nixpkgs' ssh would shadow /usr/bin/ssh and does not support
      #             macOS Keychain (`UseKeychain yes`). Use the system client.
      #   tailscale — use the Tailscale macOS app, which ships the Network
      #               Extension; nixpkgs' tailscaled is a poor fit on darwin.
      profilePackages = with pkgs; [
        git
        curl
        btop
        fish
        neovim
        starship
        eza
        ripgrep
        fd
        fzf
        dotbot
        gh
        mosh
        zedApp
        ghosttyApp
        codexApp
        claudeCode
        herdrPkg
      ];
    in
    {
      packages.${system} = {
        default = pkgs.buildEnv {
          name = "pikpik";
          paths = profilePackages;
        };
        zed = zedApp;
        ghostty = ghosttyApp;
        codex = codexApp;
        claude-code = claudeCode;
        herdr = herdrPkg;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = profilePackages;
      };
    };
}
