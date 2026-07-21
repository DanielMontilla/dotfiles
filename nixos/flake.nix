{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
		nix-flatpak = {
			url = "github:gmodena/nix-flatpak";
		};
		opencode-flake = {
			url = "github:anomalyco/opencode/56d818fc348f677c1f371f22a4354e815a4de866";
		};
		ghostty = {
			url = "github:ghostty-org/ghostty";
		};
	};

	nixConfig = {
		extra-substituters = [ "https://ghostty.cachix.org" ];
		extra-trusted-public-keys = [ "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=" ];
	};

	outputs = { self, nixpkgs, nix-flatpak, opencode-flake, ghostty, ... }@inputs: {
		nixosConfigurations.olimar = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				nix-flatpak.nixosModules.nix-flatpak
				./hosts/olimar/configuration.nix
			];
		};
		nixosConfigurations.louie = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				nix-flatpak.nixosModules.nix-flatpak
				./hosts/louie/configuration.nix
			];
		};
		nixosConfigurations.hocotate = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/hocotate/configuration.nix
			];
		};
	};
}