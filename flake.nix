{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        gleam
        rebar3
        beamPackages.erlang
      ];
    };
  };
}
