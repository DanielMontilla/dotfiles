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
		nixosConfigurations.loui = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/loui/configuration.nix
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