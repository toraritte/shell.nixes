####################################################################
# Importing a cloned Nixpkgs repo  (from my home directory), because
# the latest channels don't have Elixir 1.9.
# See https://nixos.org/nix/manual/#idm140737317975776 for the meaning
# of `<nixpkgs>` and `~` in Nix expressions (towards the end of that
# section).
####################################################################

# #               VVVVVVVVVVVVVVVV
# { pkgs ? import ~/clones/nixpkgs {} }:

let
  nixpkgs_commit = "f5054121cb287317c4ca8c409ef9c68f36658013"; # 2022-03-29T03:03:59Z
  pinnedNixpkgsGithubURL = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs_commit}.tar.gz";
  # Going  with  this  variant  of `fetchTarball`  as  it  doesn't
  # require the sha256 dance
  fetchedPinnedTarball = builtins.fetchTarball pinnedNixpkgsGithubURL;

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"

  # nixpkgs_sha256 = "01bmiqndp1czwjw87kp21dvxs0zwv7yypqlyp713584iwncxjv0r";
  # fetchedPinnedTarball =
  #   builtins.fetchTarball
  #     { name = "nixpkgs";
  #       url = pinnedNixpkgsGithubURL;
  #       sha256 = nixpkgs_sha256;
  #     }
  # ;

in

  { pkgs ? import fetchedPinnedTarball {} }:

  pkgs.mkShell {

    buildInputs = with pkgs; [
      # Not sure  what the best  way to  find the latest  major Erlang
      # version  available  in  Nixpkgs  so   I  usually  just  go  to
      # nixpkgs/pkgs/development/interpreters/erlang/  and see  what's
      # there.
      beam.packages.erlangR24.erlang
      beam.packages.erlangR24.rebar3
      git
    ];

    ####################################################################
    # Without  this, almost  everything  fails with  locale issues  when
    # using `nix-shell --pure` (at least on NixOS).
    # See
    # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
    # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
    ####################################################################

    LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  }
