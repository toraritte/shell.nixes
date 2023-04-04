######################################################################
# Clean up after exiting the Nix shell using 'trap'.                 #
# ------------------------------------------------------------------ #
# Idea taken from                                                    #
#   Killing background processes started in nix-shell                #
#   https://unix.stackexchange.com/questions/464106/                 #
# and the answer provides a way more sophisticated solution.         #
#                                                                    #
# The main syntax is 'trap ARG SIGNAL' where ARG are the commands to #
# be executed when SIGNAL crops up. See 'trap --help' for more.      #
######################################################################

echo
echo '=============='
echo 'CLEANING UP...'
echo '=============='

########################################################
# Stop PostgreSQL                                      #
########################################################

pg_ctl -D $PGDATA stop

########################################################
# Delete '.nix-shell' directory                        #
# ----------------------------------                   #
# The first  step is going  back to the  project root, #
# otherwise '.nix-shell'  won't get deleted.  At least #
# it didn't for me when exiting in a subdirectory.     #
########################################################

cd $PWD
rm -rf $NIX_SHELL_DIR
