
let
  nixpkgs_commit = "cfed29bfcb28259376713005d176a6f82951014a";
  nixpkgs_sha256 = "034m892hxygminkj326y7l3bp4xhx0v154jcmla7wdfqd23dk5xm";
  pkgs = import (builtins.fetchTarball {
    name = "nixpkgs";
    url = "https://github.com/nixos/nixpkgs/tarball/${nixpkgs_commit}";
    sha256 = nixpkgs_sha256;
  }) { config = {}; overlays = []; };
  python = pkgs.python37;
  result = import ./machnix.nix { inherit pkgs python; };
  manylinux1 = pkgs.pythonManylinuxPackages.manylinux1;
  overrides = result.overrides manylinux1 pkgs.autoPatchelfHook;
  py = python.override { packageOverrides = overrides; };
in
py.withPackages (ps: result.select_pkgs ps)
