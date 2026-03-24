#!/bin/sh
# shellcheck shell=sh

curl --fail-with-body -L https://raw.githubusercontent.com/romkatv/zsh-bin/master/install | sh -s -- -d ~/.local -e "no"
