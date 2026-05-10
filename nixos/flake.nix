{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		nix-flatpak = {
			url = "github:gmodena/nix-flatpak";
		};
		opencode-flake = {
			url = "github:anomalyco/opencode/dev";
		};
	};

	outputs = { self, nixpkgs, nix-flatpak, opencode-flake, ... }@inputs: {
		nixosConfigurations.framework = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				nix-flatpak.nixosModules.nix-flatpak
				./hosts/framework/configuration.nix
			];
		};
		nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/homelab/configuration.nix
			];
		};
	};
}