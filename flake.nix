{
  description = "Darker Cavern development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    devShells.aarch64-darwin.default =
      let pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      in pkgs.mkShell {
        packages = [
          pkgs.guile
          pkgs.guile-hoot
          pkgs.guile-goblins
          pkgs.guile-fibers
          pkgs.guile-gnutls
        ];
        shellHook = ''
          exec zsh
        '';
      };
  };
}
