{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    gleam.url = "github:Comamoca/gleam-overlay";
  };
  outputs = {
    nixpkgs,
    gleam,
    ...
  }: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ] (system:
        function (import nixpkgs {
          inherit system;
          overlays = [gleam.overlays.default];
        }));
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShellNoCC {
        buildInputs = with pkgs; [
          pkgs.gleam.bin.latest
          rebar3
          beamPackages.erlang
        ];
      };
    });
  };
}
