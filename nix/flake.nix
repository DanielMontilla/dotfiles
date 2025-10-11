{
  description = "Daniel's NixOS configuration";

  inputs = {
  	nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      my-packages = [
	pkgs.git
	pkgs.firefox
	pkgs.bitwarden
	pkgs.neovim
	pkgs.dotbot
	pkgs.sway
	pkgs.foot
      ];
    in {
	packages.${system}.default = pkgs.buildEnv {
		name = "home";
		paths = my-packages;
	};
    };
}
