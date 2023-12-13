#!/bin/bash

script_path=$(dirname "$0")
out_path="$script_path"/../out

ninja -C "$out_path"/arm64
ninja -C "$out_path"/x86_64

rm -rf "$out_path"/universal
mkdir -p "$out_path"/universal

# https://chromium.googlesource.com/chromium/src/+/main/docs/mac_arm64.md#universal-builds
"$script_path"/universalizer.py \
  "$out_path"/arm64/Switcher.app \
  "$out_path"/x86_64/Switcher.app \
  "$out_path"/universal/Switcher.app
