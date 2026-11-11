{
  description = "pikpik — macOS work machine (nix-darwin)";

  inputs = {
    # The `-darwin` branch is the release branch plus macOS-specific fixes that
    # have not reached `nixos-26.05` yet. For a Darwin-only flake it is the
    # correct pin (and it tracks the same package versions).
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Release branch matching the nixpkgs input above. `follows` keeps a single
    # nixpkgs in the lock file, so the system profile and the dev shell agree.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin }:
    let
      # Apple Silicon only. nixpkgs 26.05 is the last release with Intel macOS
      # support, so an x86_64-darwin configuration would rot immediately.
      system = "aarch64-darwin";

      # Claude Code is unfree; allow only it, not everything.
      allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfreePredicate = allowUnfreePredicate;
      };

      cliPackages = import ./packages.nix { inherit pkgs unstable; };
    in
    {
      darwinConfigurations.pikpik = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit unstable; };
        modules = [
          ./configuration.nix

          # Shows up in `darwin-version` so a generation can be traced back to
          # a commit. `dirtyRev` covers uncommitted builds.
          { system.configurationRevision = self.rev or self.dirtyRev or null; }
        ];
      };

      # Same CLI set, for `nix develop` inside the repo.
      devShells.${system}.default = pkgs.mkShell { packages = cliPackages; };

      # `nix build .#darwinPackages.<pkg>` convenience, as in the nix-darwin
      # template flake.
      darwinPackages = self.darwinConfigurations.pikpik.pkgs;
    };
}
