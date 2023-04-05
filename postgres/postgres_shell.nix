# Quickstart with PostgreSQL
# ==========================
#
#     createdb $(whoami) --host=$PGDATA --port=5432
#     psql --host=$PGDATA --username=$(whoami) --dbname=$(whoami) --port=5432
#
# `--port` is  only needed  when used  something other
# than the default port of 5432.

# TODOs {{-
#
# + `pga_hba.conf` in  here is super-insecure;
#   tighten  it  up  (or, at  least,  make  it
#   configurable  and/or  add notes  for  best
#   practices).
#
# + Make  it  possible   to  specify  specific
#   PostgreSQL    version    (currently,    it
#   depends  on  the  latest  version  in  the
#   nixpkgs_commit)
# }}-

# QUESTIONs {{-
#
# + Currently,   after    running   this   Nix
#   expression,  the  PostgreSQL superuser  is
#   whoever the current user is.
#   +-> Is this normal?
#   +-> How is it set?
#   +-> Did I influence this  with  any of the settings
#      below?
#
# }}-

{ nixpkgs_commit # See head of `baseline_config.nix` if also want to pass pkg sets.
, raw_github_url_to_shell_nix_dir ? ""
}:

let

  # The downloaded archive will be (temporarily?) housed in the Nix store
  # e.g., "/nix/store/gk9x7syd0ic6hjrf0fs6y4bsd16zgscg-source"
  # (Try any of the `fetchTarball` commands  below  in `nix repl`, and it
  #  will print out the path.)
  nixpkgs_tarball =
    builtins.fetchTarball
      "https://github.com/nixos/nixpkgs/tarball/${nixpkgs_commit}"
  ;
  pkgs =
    (import nixpkgs_tarball)
      { config = {}; overlays = []; }
  ;

  _utils_file =
    builtins.fetchurl
      "https://github.com/toraritte/shell.nixes/raw/dev/_utils.nix"
  ;
  # short for shell.nixes_utils
  snutils =
    (import _utils_file)
      { remote_prefix = raw_github_url_to_shell_nix_dir;
        working_dir = ./.;
      }
  ;

in

  pkgs.mkShell {

    buildInputs = with pkgs; [
      postgresql
    ];

    shellHook =
        snutils.f "shell-hook.sh"
      + snutils.c ["clean-up.sh"]
      #+ c ["../t" "clean-up.sh" "../t"]
    ;

    ######################################################################
    # Without  this, almost  everything  fails with  locale issues  when #
    # using `nix-shell --pure` (at least on NixOS).                      #
    # See                                                                #
    # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702    #
    # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June#023900.html
    ######################################################################

    LOCALE_ARCHIVE =
      if pkgs.stdenv.isLinux
      then "${pkgs.glibcLocales}/lib/locale/locale-archive"
      else ""
    ;
  }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
