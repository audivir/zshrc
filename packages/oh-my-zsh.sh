#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

curl --fail-with-body -L https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- \
  --unattended \
  --keep-zshrc
