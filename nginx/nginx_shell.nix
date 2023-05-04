# TEST ONE-LINERS {{-
# + mac
#
#   * Calling from `shell.nixes` project root:
#
#       nix-shell --argstr "nixpkgs_commit" "nixpkgs-22.11-darwin" --argstr "_utils_file" "file://$(realpath _utils.nix)" postgres/postgres_shell.nix --show-trace
#
#     or
#
#       source run.sh -g https://github.com/toraritte/shell.nixes/blob/main/postgres/postgres_shell.nix
#
#   * Calling remotely (once commits are pushed, that is):
#
#       source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh) -g https://github.com/toraritte/shell.nixes/blob/main/postgres/postgres_shell.nix
#
# + linux:
#
#   same but replace "nixpkgs-22.11-darwin" with "22.11" (or other)
#
# }}-

{ nixpkgs_commit # See head of `baseline_config.nix` if also want to pass pkg sets.
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

# NOTE https://discourse.nixos.org/t/how-to-add-local-files-into-nginx-derivation-for-nix-shell/6603
# Opted to keep `nginx.conf` out of the store, because
# 1. it is already in version control
# 2. if changes need to be made, one would have to create another config to override it
# -- Although, are there merits to keep it in the store?
#    + with NixOS, this would be a no brainer, but then the config would have to be rebuilt
#    + if a default config is kept in the store, it could still be over-ridden with another one using `-c`
#    Nonetheless, when this repo is deployed via a `shell.nix`, it may be more convenient to refer to a non-store config.

# let
#   nginx-with-config = pkgs.writeScriptBin "nginx-alt" ''
#     exec ${pkgs.nginx}/bin/nginx -c ${./nginx.conf} "$@"
#   '';
#
# in

in

  pkgs.mkShell {

    buildInputs = [
      # TODO for when a `just` recipe is created for NGINX: it runs as a daemon by default, same as PostgreSQL! Set trap / clean-up step to shut it down when exiting the shell.
      pkgs.nginx
    ];


    shellHook =
      ''
        call_nginx () {
          exec ${pkgs.nginx}/bin/nginx -p $(pwd) -c nginx.conf "$@"
        }

        export NGINX_DIR="_nix-shell/nginx"
        mkdir -p $NGINX_DIR

        call_nginx
      ''

      # NOTE It may  take some  time for NGINX  to shut
      #      down; the line in `ps ax` is a good sign:
      #
      # 2814526 ? S 0:00 nginx: worker process is shutting down

    + ''
        trap \
          "
          call_nginx -s quit
          " \
          EXIT
      ''
    ;
  }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
