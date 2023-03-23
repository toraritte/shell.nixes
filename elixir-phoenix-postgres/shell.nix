####################################################################
# Importing a cloned Nixpkgs repo  (from my home directory), because
# the latest channels don't have Elixir 1.9.
# See https://nixos.org/nix/manual/#idm140737317975776 for the meaning
# of `<nixpkgs>` and `~` in Nix expressions (towards the end of that
# section).
####################################################################

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
#       -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/elixir-phoenix-postgres/shell.nix")' \
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
    # beam.packages.erlangR22.elixir_1_9
    elixir
    # postgresql_11
    postgresql
    nodejs-12_x
    git
    # TODO this will won't install on mac
    inotify-tools
  ];

  shellHook = ''

    ######################################################################
    # Create a diretory for the generated artifacts                      #
    ######################################################################

    mkdir .nix-shell
    export NIX_SHELL_DIR=$PWD/.nix-shell

    ######################################################################
    # Put the PostgreSQL databases in the project diretory.              #
    ######################################################################

    export PGDATA=$NIX_SHELL_DIR/db

    ####################################################################
    # Put any Mix-related data in the project directory
    ####################################################################

    export MIX_HOME="$NIX_SHELL_DIR/.mix"
    export MIX_ARCHIVES="$MIX_HOME/archives"

    ######################################################################
    # Clean up after exiting the Nix shell using `trap`.                 #
    # ------------------------------------------------------------------ #
    # Idea taken from                                                    #
    # https://unix.stackexchange.com/questions/464106/killing-background-processes-started-in-nix-shell
    # and the answer provides a way more sophisticated solution.         #
    #                                                                    #
    # The main syntax is `trap ARG SIGNAL` where ARG are the commands to #
    # be executed when SIGNAL crops up. See `trap --help` for more.      #
    ######################################################################

    trap \
      "
        ########################################################
        # Stop PostgreSQL                                      #
        ########################################################

        pg_ctl -D $PGDATA stop

        ########################################################
        # Delete `.nix-shell` directory                        #
        # ----------------------------------                   #
        # The first  step is going  back to the  project root, #
        # otherwise `.nix-shell`  won't get deleted.  At least #
        # it didn't for me when exiting in a subdirectory.     #
        ########################################################

        cd $PWD
        rm -rf $NIX_SHELL_DIR
      " \
      EXIT

    ######################################################################
    # If database is  not initialized (i.e., $PGDATA  directory does not #
    # exist), then set  it up. Seems superfulous given  the cleanup step #
    # above, but handy when one had to force reboot the iron.            #
    ######################################################################

    if ! test -d $PGDATA
    then

      ########################################################
      # Init PostgreSQL                                      #
      #                                                      #
      # NOTE `initdb` vs `createdb`                          #
      # https://stackoverflow.com/questions/50210158/whats-the-difference-between-initdb-usr-local-var-db-and-createdb-db
      # https://www.postgresql.org/docs/current/app-initdb.html
      ########################################################

      pg_ctl initdb -D  $PGDATA

      ########################################################
      # PORT ALREADY IN USE                                  #
      ########################################################
      # If another `nix-shell` is  running with a PostgreSQL #
      # instance,  the logs  will show  complaints that  the #
      # default port 5432  is already in use.  Edit the line #
      # below with  a different  port number,  uncomment it, #
      # and try again.                                       #
      ########################################################

      # sed -i "s|^#port.*$|port = 5433|" $PGDATA/postgresql.conf

    fi

    ########################################################################
    # Configure and start PostgreSQL                                       #
    # ==================================================================== #
    # Setting all  necessary configuration  options via  `pg_ctl` (which   #
    # is  basically  a wrapper  around  `postgres`)  instead of  editing   #
    # `postgresql.conf` directly with `sed`. See docs:                     #
    #                                                                      #
    # + https://www.postgresql.org/docs/current/app-pg-ctl.html            #
    # + https://www.postgresql.org/docs/current/app-postgres.html          #
    #                                                                      #
    # See more on the caveats at                                           #
    # https://discourse.nixos.org/t/how-to-configure-postgresql-declaratively-nixos-and-non-nixos/4063/1
    # but recapping out of paranoia:                                       #
    #                                                                      #
    # > use `SHOW`  commands to  check the  options because  `postgres -C` #
    # > "_returns values  from postgresql.conf_" (which is  not changed by #
    # > supplying  the  configuration options  on  the  command line)  and #
    # > "_it does  not reflect  parameters supplied  when the  cluster was #
    # > started._"                                                         #
    #                                                                      #
    # OPTION SUMMARY                                                       #
    # -------------------------------------------------------------------- #
    #                                                                      #
    #  + `unix_socket_directories`                                         #
    #                                                                      #
    #    PostgreSQL  will  attempt  to create  a  pidfile  in              #
    #    `/run/postgresql` by default, but it will fail as it              #
    #    doesn't exist. By  changing the configuration option              #
    #    below, it will get created in $PGDATA.                            #
    #                                                                      #
    #   + `listen_addresses`                                               #
    #                                                                      #
    #     In   tandem  with   edits   in  `pg_hba.conf`   (see             #
    #     `HOST_COMMON`  below), it  configures PostgreSQL  to             #
    #     allow remote connections (otherwise only `localhost`             #
    #     will get  authorized  and  the  rest  of the traffic             #
    #     will be discarded).                                              #
    #                                                                      #
    #     NOTE: the  edit  to  `pga_hba.conf`  needs  to  come             #
    #           **before**  `pg_ctl  start`  (or  the  service             #
    #           needs to be restarted otherwise), because then             #
    #           the changes are not being reloaded.                        #
    #                                                                      #
    #     More info  on setting up and  troubleshooting remote             #
    #     PosgreSQL connections (these are  all mirrors of the             #
    #     same text; again, paranoia):                                     #
    #                                                                      #
    #       + https://stackoverflow.com/questions/24504680/connect-to-postgres-server-on-google-compute-engine
    #       + https://stackoverflow.com/questions/47794979/connecting-to-postgres-server-on-google-compute-engine
    #       + https://medium.com/scientific-breakthrough-of-the-afternoon/configure-postgresql-to-allow-remote-connections-af5a1a392a38
    #       + https://gist.github.com/toraritte/f8c7fe001365c50294adfe8509080201#file-configure-postgres-to-allow-remote-connection-md
    #
    #   + `log*`                                                           #
    #                                                                      #
    #     Setting up basic logging,  to see remote connections             #
    #     for example.                                                     #
    #                                                                      #
    #     See the docs for more:                                           #
    #     https://www.postgresql.org/docs/current/runtime-config-logging.html
    ########################################################################

    # !!!!!!!!!!!! These are only suitable for development.
    # ! INSECURE ! (Not sure if running a production server
    # !!!!!!!!!!!!  from `nix-shell` is a good idea anyway:)

    HOST_COMMON="host\s\+all\s\+all"
    sed -i "s|^$HOST_COMMON.*127.*$|host all all 0.0.0.0/0 trust|" $PGDATA/pg_hba.conf
    sed -i "s|^$HOST_COMMON.*::1.*$|host all all ::/0 trust|"      $PGDATA/pg_hba.conf

    pg_ctl                                                  \
      -D $PGDATA                                            \
      -l $PGDATA/postgres.log                               \
      -o "-c unix_socket_directories='$PGDATA'"             \
      -o "-c listen_addresses='*'"                          \
      -o "-c log_destination='stderr'"                      \
      -o "-c logging_collector=on"                          \
      -o "-c log_directory='log'"                           \
      -o "-c log_filename='postgresql-%Y-%m-%d_%H%M%S.log'" \
      -o "-c log_min_messages=info"                         \
      -o "-c log_min_error_statement=info"                  \
      -o "-c log_connections=on"                            \
      start

    ####################################################################
    # Install Node.js dependencies if not done yet.
    ####################################################################

    if test -d "$PWD/assets/" && ! test -d "$PWD/assets/node_modules/"
    then
      (cd assets && npm install)
    fi

    ####################################################################
    # If $MIX_HOME doesn't exist, set it up.
    ####################################################################

    if ! test -d $MIX_HOME
    then

      ######################################################
      # ...  but first,  test whether  there is  a `_backup`
      # directory. Had issues with  installing Hex on NixOS,
      # and Hex and  Phoenix can be copied  from there, just
      # in case.
      ######################################################

      if test -d "$PWD/_backup"
      then
        cp -r _backup/.mix .nix-shell/
      else
        ######################################################
        # Install Hex and Phoenix via the network
        ######################################################

        yes | mix local.hex
        yes | mix archive.install hex phx_new
      fi
    fi

    if test -f "mix.exs"
    then
      # These are not in the  `if` section above, because of
      # the `hex` install glitch, it  could be that there is
      # already a `$MIX_HOME` folder. See 2019-08-05_0553

      mix deps.get

      ######################################################
      # `ecto.setup` is defined in `mix.exs` by default when
      # Phoenix  project  is  generated via  `mix  phx.new`.
      # It  does  `ecto.create`,   `ecto.migrate`,  and  run
      # `priv/seeds`.
      ######################################################
      mix ecto.setup
    fi
  '';

  ####################################################################
  # Without  this, almost  everything  fails with  locale issues  when
  # using `nix-shell --pure` (at least on NixOS).
  # See
  # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
  # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
  ####################################################################

  LOCALE_ARCHIVE = if pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
}

# vim: set tabstop=2 shiftwidth=2 expandtab:
