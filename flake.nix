{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-vscode-extensions, ... }:
    let
      mkHome = { system, username, homeDirectory, extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home.nix
          ] ++ extraModules;
          extraSpecialArgs = {
            inherit username homeDirectory;
            vscode-marketplace = nix-vscode-extensions.extensions.${system}.vscode-marketplace;
          };
        };
    in
    {
      homeConfigurations = {
        darwin = mkHome {
          system = "aarch64-darwin";
          username = "ekamil";
          homeDirectory = "/Users/ekamil";
          extraModules = [ ./hosts/darwin.nix ];
        };

        linux = mkHome {
          system = "x86_64-linux";
          username = "ekamil";
          homeDirectory = "/home/ekamil";
          extraModules = [ ./hosts/linux.nix ];
        };
      };
    };
}
