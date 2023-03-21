# Quickstart with PostgreSQL
# ==========================
#
#     createdb $(whoami) --host=$PGDATA --port=5432
#     psql --host=$PGDATA --username=$(whoami) --dbname=$(whoami) --port=5432
#
# `--port` is  only needed  when used  something other
# than the default port of 5432.

# ISSUES {{-
#
# + `pga_hba.conf` in here is super-insecure; tighten it
#   up (or, at least, add notes for best practices).
#
# + QUESTION Currently,   after    running   this   Nix
#            expression,  the  PostgreSQL superuser  is
#            whoever the current user is.
#   +-> Is this normal?
#   +-> How is it set?
#   +-> Did I influence this  with  any of the settings
#      below?
#
# }}-

# NOTE **Default `nixpkgs_commit` {{-
#
# The Nixpkgs commit used for pinning below is quite old,
#
#     Oct 1, 2021, 8:37 PM EDT
#     https://github.com/NixOS/nixpkgs/tree/751ce748bd1ebac94442dfeaa8bc3f100d73a9f6
#
# but they can be overridden using `nix-shell`'s `--argstr`
# (never figured out how to use `--arg`):
#
#     nix-shell \
#       -v      \
#       -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/_composables/postgres_shell.nix")' \
#       --argstr "nixpkgs_commit" "3ad7b8a7e8c2da367d661df6c3742168c53913fa"
#
#  (And all that on one line:
#  nix-shell  -v -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/_composables/postgres_shell.nix")' --argstr "nixpkgs_commit" "3ad7b8a7e8c2da367d661df6c3742168c53913fa"
#  )
#
# The rules to compose "raw" GitHub links from the regular view page seems straightforward:
#
#      https://github.com/               toraritte/shell.nixes/blob/main/elixir-phoenix-postgres/shell.nix
#      https://raw.githubusercontent.com/toraritte/shell.nixes/     main/elixir-phoenix-postgres/shell.nix
#
# }}-

# TODO Make it possible to specify specific PostgreSQL version (currently, it depends on the latest version in the nixpkgs_commit)
{ nixpkgs_commit ? "751ce748bd1ebac94442dfeaa8bc3f100d73a9f6" }:

let
  pkgs =
    import
      # The downloaded archive will be (temporarily?) housed in the Nix store
      # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
      # (Try any of the `fetchTarball` commands  below  in `nix repl`, and it
      #  will print out the path.)
      ( builtins.fetchTarball "https://github.com/nixos/nixpkgs/tarball/${nixpkgs_commit}" )
      { config = {}; overlays = []; }
  ;
in


pkgs.mkShell {

  buildInputs = with pkgs; [
    postgresql
  ];

  shellHook = builtins.readFile ./shell-hook.sh;

  ######################################################################
  # Without  this, almost  everything  fails with  locale issues  when #
  # using `nix-shell --pure` (at least on NixOS).                      #
  # See                                                                #
  # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702    #
  # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June#023900.html
  ######################################################################

  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
}

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
