# An alternative to the primitive approach below would
# be using `niv`; see https://nixos.org/guides/towards-reproducibility-pinning-nixpkgs.html

let
  # git SHA1 commit hash in the NixOS/nixpkgs github repo
  # ( This will get Deno 1.8.3; to get the hash  of the
  #   most recent Nix expression,
  #
  #     1. either go to https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/web/deno/default.nix
  #        and search for  the  text "Latest commit" (which
  #        will be followed by the abbreviated commit hash)
  #
  #     2. or  issue  the  command  below  in  your  cloned
  #        Nixpkgs repo  (make  sure the latest changes are
  #        fetched):
  #
  #        git log --oneline --follow -- pkgs/development/web/deno/default.nix | head -1
  #
  # and update the `commitHash` variable below.
  commitHash = "f4593ab";
  pinnedNixpkgsGithubURL = "https://github.com/NixOS/nixpkgs/archive/${commitHash}.tar.gz";

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
  fetchedTarball = builtins.fetchTarball pinnedNixpkgsGithubURL;
in
  # If  this  expression  is  called  without  a  `pkgs`
  # argument, import the fixed one fetched above.
  { pkgs ? import fetchedTarball {} }:

  pkgs.mkShell {
    buildInputs = [ pkgs.deno ];
  }
