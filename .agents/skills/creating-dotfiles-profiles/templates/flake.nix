{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "<profile-name>";
        paths = with pkgs; [
          git
          curl
          btop
          fish
          neovim
          starship
          eza
          dotbot
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          curl
          btop
          fish
          neovim
          starship
          eza
          dotbot
        ];
      };
    };
}
