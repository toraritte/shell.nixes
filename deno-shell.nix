# An alternative to the primitive approach below would
# be using `niv`; see https://nixos.org/guides/towards-reproducibility-pinning-nixpkgs.html

# To  get a  specific  version  (older, newer,  later,
# etc.)  of  Deno,   either  update  the  `nixpkgs_commit`
# variable (see  comment after  "let") or  provide the
# Nixpkgs  github archive  link pinned  to a  specific
# commit on the command  line when calling `nix-shell`
# (see comment after "in").

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
  # and update the `nixpkgs_commit` variable below.
  nixpkgs_commit = "f4593ab";
  nixpkgs_sha256 = "01bmiqndp1czwjw87kp21dvxs0zwv7yypqlyp713584iwncxjv0r";
  pinnedNixpkgsGithubURL = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs_commit}.tar.gz";

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
  fetchedPinnedTarball = builtins.fetchTarball {
    name = "nixpkgs";
    url = pinnedNixpkgsGithubURL;
    sha256 = nixpkgs_sha256;
  };
  # fetchedPinnedTarball = builtins.fetchTarball pinnedNixpkgsGithubURL;
in
  # If  `nix-shell`  is  simply  called  with  this  Nix
  # expression,  then  the  used Nixpkgs  link  will  be
  # pinned to the `nixpkgs_commit` above.
  #
  # These are equivalent:
  #
  #     $ nix-shell deno-shell.nix
  #
  #     $ nix-shell -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/deno-shell.nix")'
  #
  # A pinned link can also be used directly by
  #
  #     $ nix-shell --arg pkgs 'import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/f4593ab.tar.gz") {}' deno-shell.nix
  #
  # which will override everything above.
  { pkgs ? import fetchedPinnedTarball {} }:

  pkgs.mkShell {
    buildInputs = [ pkgs.deno ];
  }
