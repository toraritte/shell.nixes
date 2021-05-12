{ nixShellDataDir ? ".nix-shell"
, cavern          ? ""
, rump            ? ""
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

  # Technically (to the best of  my knowledge) it is not
  # necessary to export NIX_SHELL_DIR because this shell
  # script will be run in the new sub-shell therefore it
  # would be  in scope even  in a variable (just  as the
  # CLEANUP_CALLBACKS  array) but  it  may  be a  proper
  # thing to  do; who knows,  there may be a  setup that
  # needs additional sub-shells.

  export NIX_SHELL_DIR=$PWD/${nixShellDataDir}

  # The    CLEANUP_CALLBACK_NAMES    string   and    the
  # CLEANUP_CALLBACKS  array provide  two mechanisms  to
  # register callbacks  to be run in  the clean-up phase
  # (see 3. CLEAN-UP section below); both are equivalent
  # in terms of results.

  CLEANUP_CALLBACKS=()

  # HISTORICAL NOTE:
  # 
  # This has been  added when I could not  get arrays to
  # work,  and thought  that it  is because  `nix-shell`
  # will  only start  the new  sub-shell after  sourcing
  # this  script -  and  arrays cannot  be exported.  So
  # added  this function  to  collect  all the  callback
  # names in a  string, which *can* be  exported, and it
  # is later  broken up  into an  array in  the clean-up
  # phase (see 3. CLEAN-UP section below).
  # 
  # This  notion   was  not  bad  but   was  idiotically
  # implemented (the  split and conversion was  not even
  # put in  the `trap`  section but it  is part  of  the
  # same  body  of  script therefore  nothing  has  been
  # changed. As it turns out, I  just had no clue how to
  # deal with arrays; see extensive reminders below.

  export CLEANUP_CALLBACK_NAMES=""

  add_cleanup_callback_name() {
    CLEANUP_CALLBACK_NAMES+=" $1"
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
    # Bash array recap:
    # https://www.gnu.org/software/bash/manual/html_node/Arrays.html
    #
    #   * ''${!an_array[@]} returns the INDICES of an array
    #         :
    #   * ''${#an_array[@]} returns the LENGTH  of an array
    #
    #   * To assign an array to another variable:
    #
    #         array_copy=("''${an_array[@]}")
    #
    #   * Arrays and functions:
    #     https://askubuntu.com/questions/674333/how-to-pass-an-array-as-function-argument
    #
    #         a_fun() {
    #           array=($@)
    #         }
    #
    #         a_fun "''${an_array[@]}"
    #
    #   *   ''${arr_of_funs[$i]}   (the literal string at "i" index
    #                               i.e., name of the function here)
    #             =/=
    #
    #      "''${arr_of_funs[$i]}"  (executing the function that has
    #                               the name of the string at index i)
    #
    #   * https://serverfault.com/questions/477503/check-if-array-is-empty-in-bash
    #
    # SPLIT STRINGS INTO ARRAYS
    # ====================================================
    # https://stackoverflow.com/questions/10586153/how-to-split-a-string-into-an-array-in-bash
    ######################################################

  IFS=' ' read -r -a CLEANUP_CALLBACKS_ARRAY <<< $CLEANUP_CALLBACK_NAMES

  run_cleanup_callbacks() {

    CALLBACK_ARRAY=("$@")

    if [ ''${#CALLBACK_ARRAY[@]} -eq 0 ]
    then
      # Chose "success" code because no callbacks present is
      # not an erroneous condition; it only means that there
      # is nothing to clean up
      # https://tldp.org/LDP/abs/html/exitcodes.html
      echo "nothing here"
      echo
      return 0
    else
      echo "The following cleanup callbacks will run:"
      printf '+ %s\n' "''${CALLBACK_ARRAY[@]}"
      echo

      for i in "''${!CALLBACK_ARRAY[@]}"
      do
        echo "=== "''${CALLBACK_ARRAY[$i]}" ======="
        "''${CALLBACK_ARRAY[$i]}"
        echo
      done
    fi
  }

  clean_up() {
  ''
+ rump
+ ''
    echo '####################################'
    echo '### RUN WORKAROUND CALLBACKS #######'
    echo '####################################'
    echo
    run_cleanup_callbacks "''${CLEANUP_CALLBACKS_ARRAY[@]}"

    echo '####################################'
    echo '### RUN REGULAR ARRAY CALLBACKS ####'
    echo '####################################'
    echo
    run_cleanup_callbacks "''${CLEANUP_CALLBACKS[@]}"

    ######################################################
    # Delete `${nixShellDataDir}` directory
    # ----------------------------------
    # The first  step is going  back to the  project root,
    # otherwise `${nixShellDataDir}`  won't get deleted.  At least
    # it didn't for me when exiting in a subdirectory.
    ######################################################

    cd $PWD
    rm -rf $NIX_SHELL_DIR
  }

  trap \
    clean_up \
    EXIT
  ''
