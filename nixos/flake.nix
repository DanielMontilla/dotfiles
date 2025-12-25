{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };
	};

	outputs = { self, nixpkgs, sysc-greet, ... }@inputs: {
		nixosConfigurations.framework = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hosts/framework/configuration.nix
        sysc-greet.nixosModules.default
			];
		};
	};
}
