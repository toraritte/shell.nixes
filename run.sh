#!/usr/bin/env bash

# MAN(ISH) PAGE {{-

# ABSTRACT
# ====================================================
# Shell script to call `shell.nix` files remotely. (If
# want to call them locall, just use `nix-shell`.)

# SYNOPSIS
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

# EXAMPLES
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
# }}-

# https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
while [ $# -gt 0 ]; do
  case "$1" in

    --github-url-to-shell-nix|-g)
      GITHUB_URL="$2"
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

echo "NIXPKGS_COMMIT: ${NIXPKGS_COMMIT}"

# If   no    option   was   specified,    default   to
# `baseline/baseline_config.nix` in this repo
GITHUB_REPO="${GITHUB_REPO:-"toraritte/shell.nixes"}"
REPO_COMMIT_OR_REF="${REPO_COMMIT_OR_REF:-"main"}"
SHELL_NIX_PATH="${SHELL_NIX_PATH:-"baseline/baseline_config.nix"}"

DEFAULT_NIXPKGS_COMMIT="nixpkgs-22.11-darwin"
NIXPKGS_COMMIT=${NIXPKGS_COMMIT:-${DEFAULT_NIXPKGS_COMMIT}}

echo "DEFAULT_NIXPKGS_COMMIT: ${DEFAULT_NIXPKGS_COMMIT}"
echo "NIXPKGS_COMMIT: ${NIXPKGS_COMMIT}"

# The  rules to  compose "raw"  GitHub links  from the
# regular view page seems straightforward:
#
# ```text
# https://github.com/               toraritte/shell.nixes/blob/main/postgres/postgres_shell.nix
# https://raw.githubusercontent.com/toraritte/shell.nixes/     main/postgres/postgres_shell.nix
# ```

RAW_GITHUB_PREFIX="https://raw.githubusercontent.com/"

# `RAW_GITHUB_URL_TO_SHELL_NIX_DIR`
# is  the  directory   where  ancillary  files  (e.g.,
# configuration  files)  needed  for  the  `shell.nix`
# preside. (The presumption that  these are all in the
# same  directory  is  hard-coded for  now.)  See  the
# `baseline/` directory for example.

# https://tldp.org/LDP/abs/html/string-manipulation.html
if [ -z "${GITHUB_URL}" ]
then
  #<= toraritte/shell.nixes
  #<= main
  #<= baseline/baseline_config.nix
  RAW_GITHUB_URL_TO_SHELL_NIX_DIR="${RAW_GITHUB_PREFIX}${GITHUB_REPO}/${REPO_COMMIT_OR_REF}/"
  #=> https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/
  RAW_URL="${RAW_GITHUB_URL_TO_SHELL_NIX_DIR}${SHELL_NIX_PATH}"
  #=> https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline_config.nix
else
  #<= https://github.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix

  GITHUB_PATH_TO_SHELL_NIX=$(nix-shell -p gnused --run "echo $GITHUB_URL | sed 's/https\?:\/\/github.com\///g' | sed 's/blob\///g'")
  #=> toraritte/shell.nixes/blob/main/baseline/baseline_config.nix

  # had to go with sed as this is not compatible with zsh on mac
  # START_INDEX=$(expr match "${GITHUB_URL}" 'https\?://github.com/')
  # GITHUB_PATH_TO_SHELL_NIX="${GITHUB_URL:${START_INDEX}}"
  # echo "START_INDEX=${START_INDEX}"
  echo "GITHUB_PATH_TO_SHELL_NIX=${GITHUB_PATH_TO_SHELL_NIX}"

  # had to go with sed as this is not compatible with zsh on mac
  # INDEX_TO_LAST_SLASH=$(expr match ${GITHUB_PATH_TO_SHELL_NIX} '.*/')
  # GITHUB_DIR_PATH="${GITHUB_PATH_TO_SHELL_NIX:0:${INDEX_TO_LAST_SLASH}}"

  GITHUB_DIR_PATH=$(nix-shell -p gnused --run "echo $GITHUB_PATH_TO_SHELL_NIX | sed 's/\(.*\/\).*$/\1/g'")
  #=> toraritte/shell.nixes/blob/main/baseline/

  echo "GITHUB_DIR_PATH=${GITHUB_DIR_PATH}"

  RAW_GITHUB_URL_TO_SHELL_NIX_DIR="${RAW_GITHUB_PREFIX}${GITHUB_DIR_PATH}"
  #=> https://raw.githubusercontent.com/toraritte/shell.nixes/blob/main/baseline/
  RAW_URL="${RAW_GITHUB_PREFIX}${GITHUB_PATH_TO_SHELL_NIX}"
  #=> https://raw.githubusercontent.com/toraritte/shell.nixes/blob/main/baseline/baseline_config.nix
fi

echo "RAW_GITHUB_URL_TO_SHELL_NIX_DIR: ${RAW_GITHUB_URL_TO_SHELL_NIX_DIR}"
echo "RAW_URL: ${RAW_URL}"

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

nix-shell                                                      \
  --show-trace                                                 \
  -v                                                           \
  -E "import (builtins.fetchurl \"${RAW_URL}\")"               \
  --argstr "nixpkgs_commit" "${NIXPKGS_COMMIT}"                \
  --argstr "raw_github_url_to_shell_nix_dir" "${RAW_GITHUB_URL_TO_SHELL_NIX_DIR}";  \
  --arg "pkgs" "import (fetchTarball \"https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_COMMIT}.tar.gz\") {}"

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
