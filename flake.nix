{
  description = "Synapse — portable AI harness installer, stack restore, and auto-updater";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgsDarwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Pre-built packages are served from Cachix so a fresh install does not compile
  # anything. `synapse install` prompts the user to trust this; CI pushes to it.
  nixConfig = {
    extra-substituters = [ "https://synapse.cachix.org" ];
    extra-trusted-public-keys = [
      "synapse.cachix.org-1:2W4A4S39XeD4dJ1cUCVOgFRs9L2Xg1r0xdVfCEHUCzE="
    ];
  };

  outputs =
    {
      nixpkgs,
      nixpkgsDarwin,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # nixpkgs 26.11 removed x86_64-darwin. Keep that supported target on
        # the maintained 26.05 Darwin branch while every other target follows
        # nixos-unstable.
        pkgs =
          (if system == "x86_64-darwin" then nixpkgsDarwin else nixpkgs).legacyPackages.${system};

        # nixpkgs supplies Herdr everywhere except x86_64-darwin, where its
        # maintained 26.05 Darwin branch predates the package. Use that
        # platform's official upstream binary only as the narrow fallback.
        herdr =
          if system == "x86_64-darwin" then pkgs.callPackage ./nix/herdr.nix { } else pkgs.herdr;
        skillshare = pkgs.callPackage ./nix/skillshare.nix { };

        # OMP needs Bun newer than the x86_64-darwin nixpkgs package.
        bun = pkgs.callPackage ./nix/bun.nix { };
        omp = pkgs.callPackage ./nix/omp.nix { inherit bun; };

        # The Rust CLI itself.
        synapse = pkgs.rustPlatform.buildRustPackage {
          pname = "synapse";
          version = "1.2.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          # Nix build sandbox has no `which` binary; tests that probe
          # `which <bin>` need it on PATH inside the sandbox.
          nativeBuildInputs = [ pkgs.which ];
          meta.mainProgram = "synapse";
        };
      in
      {
        packages = {
          inherit
            herdr
            skillshare
            omp
            synapse
            ;

          # Every managed package in one closure, for Cachix warming and for
          # `nix-fast-build` to fan out in a single invocation.
          harness = pkgs.symlinkJoin {
            name = "synapse-harness";
            paths = [
              herdr
              skillshare
              omp
            ];
          };

          default = synapse;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cargo
            rustc
            clippy
            # Parallel package builds; CI uses it to fan out the platform matrix.
            nix-fast-build
            cachix
            nixfmt
          ];
        };
      }
    );
}
