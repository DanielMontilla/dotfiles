{
  description = "Daniel's NixOS configuration";

  inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      host = "home";
    in {
      nixosConfigurations = {
        "${host}" = nixpkgs.lib.nixosSystem {
          system = system;
          modules = [
            ./hardware-configuration.nix
            ./hosts/${host}.nix
          ];
        };
      };
    };
}
