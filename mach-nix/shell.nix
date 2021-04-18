let
  # Not  the latest  version but  seems to  be the  most
  # stable one
  # https://github.com/DavHau/mach-nix/issues/221
  mach_nix_version = "3.0.2";

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
  # (Try any of the `fetchTarball` commands  below  in `nix repl`, and it
  #  will print out the path.)
  fetchedPinnedTarball =
    builtins.fetchTarball
      { name = "mach-nix";
        url = "https://github.com/DavHau/mach-nix/tarball/${mach_nix_version}";
        sha256 = "0w6i3wx9jyn29nnp6lsdk5kwlffpnsr4c80jk10s3drqyarckl2f";
      }
  ;
  mach_nix = (import fetchedPinnedTarball {}).mach-nix;

  nixpkgs_commit = "cfed29bfcb28259376713005d176a6f82951014a";
  pinned_pkgs =
    import
      ( builtins.fetchTarball
          { name = "nixpkgs";
            url = "https://github.com/nixos/nixpkgs/tarball/${nixpkgs_commit}";
            sha256 = "034m892hxygminkj326y7l3bp4xhx0v154jcmla7wdfqd23dk5xm";
          }
      ) { config = {}; overlays = []; }
  ;
in
  # If  `nix-shell`  is  simply  called  with  this  Nix
  # expression,  then  the  used Nixpkgs  link  will  be
  # pinned to the `nixpkgs_commit` above.
  #
  # These are equivalent:
  #
  #     $ nix-shell mach-nix-shell.nix
  #
  #     $ nix-shell -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/mach-nix-shell.nix")'
  #
  # A link pinned to a specific Nixpkgs commit tarball can also be used directly by
  #
  #     $ nix-shell --arg pkgs 'import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/f4593ab.tar.gz") {}' mach-nix-shell.nix
  #
  # which will override everything above.
  { pkgs ? pinned_pkgs }:

  pkgs.mkShell
    { buildInputs = [ mach_nix ]; }
