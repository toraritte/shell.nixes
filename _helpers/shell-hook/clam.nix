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
  # 1. SETUP #########################################################
  ####################################################################

  # Create a diretory for the generated artifacts ...

  mkdir ${nixShellDataDir}
  export NIX_SHELL_DIR=$PWD/${nixShellDataDir}

  # ( The   whole  CLEAN_UP_CALLBACK_NAMES   and
  #   CLEANUP_CALLBACKS_ARRAY   shenanigans   is
  #   because bash arrays  cannot be `export`ed,
  #   hence this dirty workaround;
  #   see ../README.md about "cleanup callbacks".
  # )
  export CLEAN_UP_CALLBACK_NAMES=""

  add_cleanup_callback_name() {
    CLEAN_UP_CALLBACK_NAMES+=" $1"
  }

  ####################################################################
  # 2. ACTIONS #######################################################
  ####################################################################

  # ... set up the environment, configure apps, etc. ...
  ''
+ cavern
+ ''
  ####################################################################
  # 3. CLEAN-UP                                                      #
  # ================================================================ #
  # ... and tie up loose ends (e.g., stop db).
  #
  # Idea taken from
  # https://unix.stackexchange.com/questions/464106/killing-background-processes-started-in-nix-shell
  # and the answer provides a way more sophisticated solution.
  #
  # The main syntax is `trap ARG SIGNAL` where ARG are the commands to
  # be executed when SIGNAL crops up. See `trap --help` for more.
  ####################################################################

    ######################################################
    # WHY THE DOUBLE SINGLE QUOTES BEFORE THE DOLLAR SIGNS?
    # ====================================================
    # They are  needed because  the "dollar  curly braces"
    # construct is employed both by Nix (for antiquotation
    # a.k.a.  variable expansion)  and  bash (for  similar
    # purposes and for others; see link below); the double
    # single quotes eliminate the  special meaning for Nix
    # so it can get safely executed by the shell.
    #
    # + https://toraritte.github.io/saves/Nix-Package-Manager-Guide-Version-2.3.10.html#idm140737322052144
    # + https://stackoverflow.com/questions/8748831/when-do-we-need-curly-braces-around-shell-variables
    #
    # HELP FOR "FUNCTIONS IN ARRAYS" IN BASH
    # ====================================================
    # + https://stackoverflow.com/questions/20361398/bash-array-of-functions
    # + https://stackoverflow.com/questions/1951506/add-a-new-element-to-an-array-without-specifying-the-index-in-bash
    #
    # Reminders:
    #
    #   * the ! in the variable expansion in `for` is important
    #     (i.e., "''${!arr_of_funs[@]}")
    #
    #   *   ''${arr_of_funs[$i]}   (the literal string at "i" index
    #                               i.e., name of the function here)
    #             =/=
    #
    #      "''${arr_of_funs[$i]}"  (executing the function that has
    #                               the name of the string at index i)
    #
    # SPLIT STRINGS INTO ARRAYS
    # ====================================================
    # https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash
    ######################################################

  IFS=' ' read -r -a CLEANUP_CALLBACKS_ARRAY <<< $CLEAN_UP_CALLBACK_NAMES

  run_cleanup_callbacks() {
    echo "The following cleanup callbacks will run:"
    printf '+ %s\n' "''${CLEANUP_CALLBACKS_ARRAY[@]}"
    echo

    for i in "''${!CLEANUP_CALLBACKS_ARRAY[@]}"
    do
      echo "=== "''${CLEANUP_CALLBACKS_ARRAY[$i]}" ======="
      "''${CLEANUP_CALLBACKS_ARRAY[$i]}"
      echo
    done
  }


  trap \
    "
  ''
+ rump
+ ''
      ######################################################
      # Run clean-up callbacks
      ######################################################

      run_cleanup_callbacks

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
