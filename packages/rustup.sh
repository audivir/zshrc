#!/bin/sh
curl -L https://sh.rustup.rs | sh -s -- \
	--default-toolchain nightly-2026-01-28 \
	--no-update-default-toolchain \
	--no-modify-path -y || exit 1
