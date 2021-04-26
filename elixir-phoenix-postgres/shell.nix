####################################################################
# Importing a cloned Nixpkgs repo  (from my home directory), because
# the latest channels don't have Elixir 1.9.
# See https://nixos.org/nix/manual/#idm140737317975776 for the meaning
# of `<nixpkgs>` and `~` in Nix expressions (towards the end of that
# section).
####################################################################

{ pkgs ? import ~/clones/nixpkgs {} }:

pkgs.mkShell {

  buildInputs = with pkgs; [
    beam.packages.erlangR22.elixir_1_9
    postgresql_11
    nodejs-12_x
    git
    inotify-tools
  ];

  shellHook =
    let
      rump =
        ''
        ######################################################
        # Stop PostgreSQL
        # ---------------
        # `PGDATA` is declared in
        # ./shell-hook-inserts/postgres.nix
        ######################################################

        pg_ctl -D $PGDATA stop
        ''
      ;
      cavern =
          import ./shell-hook-inserts/postgres.nix
        + import ./shell-hook-inserts/mix.nix
      ;
    in
      import ../clam.nix { inherit cavern rump; }
  ;

#    ####################################################################
#    # Install Node.js dependencies if not done yet.
#    ####################################################################
#
#    if test -d "$PWD/assets/" && ! test -d "$PWD/assets/node_modules/"
#    then
#      (cd assets && npm install)
#    fi

  ####################################################################
  # Without  this, almost  everything  fails with  locale issues  when
  # using `nix-shell --pure` (at least on NixOS).
  # See
  # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
  # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
  ####################################################################

  LOCALE_ARCHIVE =
    if pkgs.stdenv.isLinux
    then "${pkgs.glibcLocales}/lib/locale/locale-archive"
    else ""
  ;
}
