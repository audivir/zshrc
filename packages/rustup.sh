#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

curl --fail-with-body -L https://sh.rustup.rs | sh -s -- \
	--default-toolchain nightly-2026-01-28 \
	--no-update-default-toolchain \
	--no-modify-path -y
