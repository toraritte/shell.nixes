#!/usr/bin/env bash

# --- MAN(ISH) PAGE --- {{-

# ABSTRACT
# ====================================================
# Shell script to call `shell.nix` files remotely. (If
# want to call them locall, just use `nix-shell`.)

# SYNOPSIS {{-
# ====================================================
#
# ```text
# source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh) \
#
#   --github-url-to-shell-nix | -g <github-url>
#
#   # Read WARNING below.
#   =====================
#   --github-repo             | -r <github-style-repo-designation>
#   --repo-commit-or-ref      | -c <git-commit-hash-or-reference>
#   --shell-nix-path          | -p <path-to-shell.nix-in-repo-without-leading-slash>
#   =====================
#
#   --nixpkgs-commit          | -n <git-commit-hash-or-reference-in-the-nixpkgs-repo>
# ```
#
#      > WARNING
#      >
#      > Options
#      >
#      >   + `--github-repo`,
#      >   + `--repo-commit-or-ref`, and
#      >   + `--shell-nix-path`
#      >
#      > expect    substrings   that    produce   a
#      > valid  `<github-url>`  when combined  with
#      > `"https://github.com/"`   in   the   order
#      > mentioned   at  the   beginning  of   this
#      > sentence.
#
# + `<github-url>`
#
#   The URL seen in the browser when viewing the `shell.nix` file on GitHub. For example, `https://github.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix`.
#
# + `<github-style-repo-designation>`
#
#   The current syntax is `(organization|user)/repo-name`. For example, `nixos/nixpkgs`.
#
# + `<git-commit-hash-or-reference>`
#
#   Anything that  resolves to a single  Git commit: SHA
#   hash, tag, branch name, etc in the repo provided via
#   the `--github-repo` option.
#
#   Notes to self:
#   https://stackoverflow.com/questions/73145810/how-do-git-revisions-and-references-relate-to-each-other
#
# + `<path-to-shell.nix-in-repo-without-leading-slash>`
#
#   For example, `baseline/baseline_config.nix`.
#
# + `<git-commit-hash-or-reference-in-the-nixpkgs-repo>`
#
#   Anything that  resolves to a single  Git commit: SHA
#   hash, tag, branch name, etc in the [NixOS/nixpkgs](
#   https://github.com/NixOS/nixpkgs
#   ) repo.
# }}-

# EXAMPLES {{-
# ====================================================
# Look  around in  this  repo in  `run.sh` files,  but
# here's a couple:
#
# ```text
# source run.sh -g https://github.com/nix-community/nix-environments/blob/master/envs/github-pages/shell.nix
#
# (which is the same as: )
# source run.sh -n "nixpkgs-22.11-darwin" -r "nix-community/nix-environments" -c "master" -p "envs/github-pages/shell.nix"
#
# source run.sh -g https://github.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix
#
# source run.sh -n "staging" -r "toraritte/shell.nixes" -c "main" -p "postgres/postgres_shell.nix"
#
# source run.sh -n "832bdf74072489b8da042f9769a0a2fac9b579c7" -r "toraritte/shell.nixes" -c "ebc9079" -p "baseline/baseline_config.nix"
# ```
#
# If want to call `run.sh` remotely, just replace it with:
# ```
# <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh)
# ```
# so it becomes something like this:
# ```
# source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh) -g https://github.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix
# ```
#   }}-
# }}-

# LESSONS LEARNED
#
# 1. **Forget bash/shell functions.**
#
#    They  may make  the script  more readable,
#    but  mess  up   everything  else  and  are
#    undebugable.

RAW_GITHUB_PREFIX="https://raw.githubusercontent.com/"

# This may be unnecessary, but ran into so many issues
# with rogue variables  that I'm leaving it  here as a
# charm at this point.
unset RAW_GITHUB_URL

# https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
while [ $# -gt 0 ]; do
  case "$1" in

    --github-url-to-shell-nix|-g)
      GITHUB_URL=$2
      ;;
    --github-repo|-r)
      GITHUB_REPO="$2"
      ;;
    --repo-commit-or-ref|-c)
      REPO_COMMIT_OR_REF="$2"
      ;;
    --shell-nix-path|-p)
      SHELL_NIX_PATH="$2"
      ;;
    --nixpkgs-commit|-n)
      NIXPKGS_COMMIT="$2"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
  shift
done

# --- DEFAULT VALUES ---
# If   no    option   was   specified,    default   to
# `baseline/baseline_config.nix` in this repo
GITHUB_REPO="${GITHUB_REPO:-"toraritte/shell.nixes"}"
REPO_COMMIT_OR_REF="${REPO_COMMIT_OR_REF:-"main"}"
SHELL_NIX_PATH="${SHELL_NIX_PATH:-"baseline/baseline_config.nix"}"

DEFAULT_NIXPKGS_COMMIT="nixpkgs-22.11-darwin"
NIXPKGS_COMMIT=${NIXPKGS_COMMIT:-${DEFAULT_NIXPKGS_COMMIT}}

echo "NIXPKGS_COMMIT: ${NIXPKGS_COMMIT}"

  # NOTE Why use `sed` in the `if` block  and  not shell string manipulation commands? {{-
  # Using `sed` to manipulate strings instead of
  # [Bash's built-in methods](https://tldp.org/LDP/abs/html/string-manipulation.html)
  # because they are not portable. (At least, I couldn't
  # figure out  which ones are, and  running simple Bash
  # string commands failed on macOS  as it uses ZSH, and
  # the default Bash shell is way outdated, running Bash
  # 3.x that also don't support these commands. `sed` on
  # the  other hand  is almost  always present,  and I'm
  # calling  it with  `nix-shell`, making  sure this  is
  # true.)
  # }}-

if [ -z "${GITHUB_URL}" ] # i.e., TRUE if `run.sh` was NOT invoked with `-g`
then
  #<= GITHUB_REPO        (e.g., toraritte/shell.nixes)
  #<= REPO_COMMIT_OR_REF (e.g., main)
  #<= SHELL_NIX_PATH     (e.g., baseline/baseline_config.nix)
  RAW_GITHUB_URL="${RAW_GITHUB_PREFIX}${GITHUB_REPO}/${REPO_COMMIT_OR_REF}/${SHELL_NIX_PATH}"
  #=> e.g., https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline_config.nix
else
  #<= https://github.com/<user_or_org>/<repo>/blob/<git_ref>/<path_to_shell_nix>
  #<= e.g., https://github.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix
  TO_RAW_GITHUB_PATH=$(nix-shell --pure -p gnused --run "echo ${GITHUB_URL} | sed 's/https\?:\/\/github.com\///g' | sed 's/blob\///g'")
  #=> <user_or_org>/<repo>/<git_ref>/<path_to_shell_nix>
  #=> e.g., toraritte/shell.nixes/main/baseline/baseline_config.nix

  RAW_GITHUB_URL="${RAW_GITHUB_PREFIX}${TO_RAW_GITHUB_PATH}"
  #=> https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline_config.nix
fi

# NOTE `RAW_GITHUB_URL_TO_SHELL_NIX_DIR` {{-
# is  the  directory   where  ancillary  files  (e.g.,
# configuration  files)  needed  for  the  `shell.nix`
# preside. (The presumption that  these are all in the
# same  directory  is  hard-coded for  now.)  See  the
# `baseline/` directory for example.
# }}-

#=> https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline_config.nix
RAW_GITHUB_URL_TO_SHELL_NIX_DIR=$(nix-shell --pure -p gnused --run "echo $RAW_GITHUB_URL | sed 's/\(.*\/\).*$/\1/g'")
#=> https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/

echo "RAW_GITHUB_URL: ${RAW_GITHUB_URL}"
echo "RAW_GITHUB_URL_TO_SHELL_NIX_DIR: ${RAW_GITHUB_URL_TO_SHELL_NIX_DIR}"

# WHY PROVIDE BOTH `nixpkgs_commit` AND `pkgs`? {{-
# ====================================================
# Most  `shell.nix`  files  out there  have  the  main
# header of
#
#     { pkgs ? import <nixpkgs> {}}:
#     ...
#
# but I prefer fetching the Nixpkgs package set in the
# `shell.nix` (for  now). Anyway,  it is good  to know
# how to do it both ways.
# }}-
nix-shell                                               \
  --show-trace                                          \
  -v                                                    \
  -E "import (builtins.fetchurl \"${RAW_GITHUB_URL}\")" \
  --argstr "nixpkgs_commit" "${NIXPKGS_COMMIT}"         \
  --argstr "raw_github_url_to_shell_nix_dir" "${RAW_GITHUB_URL_TO_SHELL_NIX_DIR}";  \
  --arg "pkgs" "import (fetchTarball \"https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_COMMIT}.tar.gz\") {}"

# NOTE clean up after script has run {{-
# https://www.linuxjournal.com/content/bash-trap-command
# https://unix.stackexchange.com/questions/464106/killing-background-processes-started-in-nix-shell
# https://unix.stackexchange.com/questions/360375/is-it-a-good-practice-to-delete-all-variables-at-the-end-of-a-script
# https://www.computerhope.com/unix/utrap.htm
#
# `trap`  is not  necessary here  as `nix-shell`  will
# start a  new sub-shell,  and when  it is  gone, this
# script will continue with the commands below. As for
# `shellHook`s in `shell.nix`  files, `trap` is needed
# to clean up after the  sub-shell ends. (Not sure why
# it works there though; maybe, the `nix-shell` starts
# a  sub-shell, the  `shellHook` is  ran as  a regular
# script, so  the `trap  ... EXIT`  will be  in memory
# when the sub-shell is  terminated (e.g., with ^D) so
# it can catch it.)
# }}-
# trap \
# "
echo 'cleaning up...'
unset RAW_GITHUB_PREFIX
unset GITHUB_REPO
unset REPO_COMMIT_OR_REF
unset SHELL_NIX_PATH
unset DEFAULT_NIXPKGS_COMMIT
unset NIXPKGS_COMMIT
unset RAW_GITHUB_URL
unset RAW_GITHUB_URL_TO_SHELL_NIX_DIR
unset GITHUB_URL
# " \
# RETURN

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
