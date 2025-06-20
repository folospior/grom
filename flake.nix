{
  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";
  outputs = {
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
