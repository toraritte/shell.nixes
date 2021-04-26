{ nixShellDataDir ? ".nix-shell"
, cavern
, rump ? ""
}:

# It is important putting  `cavern` (i.e., the body of
# the  `shellHook`)  before  `rump`  (i.e.,  the  code
# to  run  during  clean-up),  because  there  may  be
# environment  variables  set  up, and  clean-up  will
# reference these.
#
# For example,  `cavern` has instructions to  set up a
# directory holding all data  for the local PostgreSQL
# instance, and store this directory's name in PGDATA;
# all subsequent PostgreSQL command  will the need the
# `--host=$PGDATA` switch because things are not where
# PostgreSQL would expect by default. The stop command
# in  the clean-up  phase (updated  with `rump`)  will
# rely on this as well.

  ''
  ####################################################################
  # Create a diretory for the generated artifacts ...
  ####################################################################

  mkdir ${nixShellDataDir}
  export NIX_SHELL_DIR=$PWD/${nixShellDataDir}

  ####################################################################
  # ... and clean up after exiting the Nix shell.
  # ------------------------------------------------------------------
  # Idea taken from
  # https://unix.stackexchange.com/questions/464106/killing-background-processes-started-in-nix-shell
  # and the answer provides a way more sophisticated solution.
  #
  # The main syntax is `trap ARG SIGNAL` where ARG are the commands to
  # be executed when SIGNAL crops up. See `trap --help` for more.
  ####################################################################

  ''
+ cavern
+ ''

  trap \
    "

  ''
+ rump
+ ''

      ######################################################
      # Delete `${nixShellDataDir}` directory
      # ----------------------------------
      # The first  step is going  back to the  project root,
      # otherwise `${nixShellDataDir}`  won't get deleted.  At least
      # it didn't for me when exiting in a subdirectory.
      ######################################################

      cd $PWD
      rm -rf $NIX_SHELL_DIR
    " \
    EXIT
  ''
