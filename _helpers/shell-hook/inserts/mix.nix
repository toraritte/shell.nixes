''
####################################################################
# Put any Mix-related data in the project directory
####################################################################

export MIX_HOME="$NIX_SHELL_DIR/.mix"
export MIX_ARCHIVES="$MIX_HOME/archives"

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
    cp -r _backup/.mix $NIX_SHELL_DIR/
  else
    ######################################################
    # Install Hex and Phoenix via the network
    ######################################################

    yes | mix local.hex
    yes | mix archive.install hex phx_new
  fi
fi

####################################################################
# If there is a project mixfile present, set up dependencies and the
# database.
####################################################################

if test -f "mix.exs"
then
  # NOTE 2021-04-25_21-58:  no  clue  what  the  comment
  # below is referring to but I trust my judgement.
  # ----------------------------------------------------
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
''
