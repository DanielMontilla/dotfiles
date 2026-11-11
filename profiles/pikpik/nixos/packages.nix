# CLI packages, shared by `environment.systemPackages` (configuration.nix) and
# the dev shell (flake.nix), so the two cannot drift.
{ pkgs, unstable }:

let
  # OpenAI Codex CLI ships a prebuilt tarball; nixpkgs' `codex` builds from
  # Rust source, which is very slow on Darwin. Package the release instead.
  codexVersion = "0.167.0";
  codex = pkgs.stdenv.mkDerivation {
    pname = "codex";
    version = codexVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${codexVersion}/codex-package-aarch64-apple-darwin.tar.gz";
      hash = "sha256-r0XtRdlA15mICWIsHAKW0wmO19f61pUoRCLCKL1FRRc=";
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
      platforms = [ "aarch64-darwin" ];
      mainProgram = "codex";
    };
  };
in
with pkgs;
[
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
]
++ [
  codex
  unstable.claude-code
  unstable.herdr
]
