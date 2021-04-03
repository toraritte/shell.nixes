# An alternative to the primitive approach below would be using `niv`;
# see https://nixos.org/guides/towards-reproducibility-pinning-nixpkgs.html

let
  # git SHA1 commit hash in the NixOS/nixpkgs github repo
  commitHash = "b5e8919e566d18ec4d6c2a6a2d698cc8f012f009"; # 4/3/2021
  pinnedNixpkgsURL = "https://github.com/NixOS/nixpkgs/archive/${commitHash}.tar.gz";

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
  fetchedTarball = builtins.fetchTarball pinnedNixpkgsURL;
in
  # If  this  expression  is  called  without  a  `pkgs`
  # argument, import the fixed one fetched above.
  { pkgs ? import fetchedTarball {} }:

  pkgs.mkShell {
    buildInputs = [ pkgs.deno ];
  }
