#!/bin/sh

# To call this script from this repo, use
#
#     source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline.sh)
#
# To add arguments:
#
#     source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline.sh) "main" "ad7b8a7e8c2da367d661df6c3742168c53913fa"

# Refers to commit in this repo (or
# any  other  repo  where `RAW_URL`
# points to)
#
# COMMIT = "main" | <git commit hash>
# default: "main"

COMMIT=${1:-"main"}
RAW_URL="https://raw.githubusercontent.com/toraritte/shell.nixes/${COMMIT}/baseline/baseline_config.nix"

echo "RAW_URL: ${RAW_URL}"

# https://github.com/NixOS/nixpkgs/commit/832bdf74072489b8da042f9769a0a2fac9b579c7
# timestamp: 2023-01-12T13:44:25Z
DEFAULT_NIXPKGS_COMMIT="832bdf74072489b8da042f9769a0a2fac9b579c7"

# Refers to a commit in the NixOS/Nixpkgs
# GitHub repo
#
# NIXPKGS_COMMIT = <git commit hash>
# default: DEFAULT_NIXPKGS_COMMIT

NIXPKGS_COMMIT=${2:-${DEFAULT_NIXPKGS_COMMIT}}

echo "NIXPKGS_COMMIT: ${NIXPKGS_COMMIT}"

nix-shell                                        \
  -v                                             \
  -E "import (builtins.fetchurl \"${RAW_URL}\")" \
  --argstr "nixpkgs_commit" "${NIXPKGS_COMMIT}";

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
