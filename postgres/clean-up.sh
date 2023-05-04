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

######################################################################
######################################################################
######################################################################
####### WARNING Don't use double quotes or backticks here!   #########
####### ----------------------------------                   #########
####### ( ... or figure out how to use them without wreaking #########
#######   havoc ....                                         #########
####### )                                                    #########
######################################################################
######################################################################
######################################################################

echo
echo '=============='
echo 'CLEANING UP...'
echo '=============='

########################################################
# Stop PostgreSQL                                      #
########################################################

pg_ctl -D $PGDATA stop

# TODO Add switch to optionally remove the "postgres" directory (which includes PGDATA)?
