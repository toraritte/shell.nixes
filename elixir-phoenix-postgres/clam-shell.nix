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
      cavern =
          import ../_helpers/shell-hook/inserts/postgres.nix
        +
          ''
          # Extend `postgres.nix` with project-specific
          # database commands.
          # (e.g., user, control flags, etc.)
          ''
        +
          import ../_helpers/shell-hook/inserts/mix.nix
        +
          ''
          workaround_callback_1() { echo "workaround 1 works"; }
          add_cleanup_callback_name "workaround_callback_1"
          ''
        +
          ''
          workaround_callback_2() { echo "workaround 2 works"; }
          add_cleanup_callback_name "workaround_callback_2"
          ''
        +
          ''
          regular_array_callback_1() { echo "regular 1 works too"; }
          CLEANUP_CALLBACKS+=( "regular_array_callback_1" )
          ''
        +
          ''
          regular_array_callback_2() { echo "regular 2 works too"; }
          CLEANUP_CALLBACKS+=( "regular_array_callback_2" )
          ''
      ;
      rump =
        ''
        echo
        echo "======================"
        echo "Arbitrary actions here"
        echo "======================"
        echo
        ''
    ;
    in
      import ../_helpers/shell-hook/clam.nix { inherit rump cavern; }
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
