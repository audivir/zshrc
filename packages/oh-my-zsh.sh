#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
curl --fail-with-body -L "$url" | sh -s -- -unattended --keep-zshrc
