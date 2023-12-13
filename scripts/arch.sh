#!/bin/bash

script_path=$(dirname "$0")
out_path="$script_path"/../out

file "$out_path"/arm64/Switcher.app/Contents/MacOS/Switcher
file "$out_path"/x86_64/Switcher.app/Contents/MacOS/Switcher
