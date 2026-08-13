#!/bin/bash

# Sends USR1 signal to running nvims to cause them to pull in a clipboard update

# Make sure nvim exists
if ! command -v nvim &>/dev/null; then exit 0; fi

# If nvim version is too old, it may crash on USR1, so don't try it
NVIM_VER="`nvim -v | grep '^NVIM' | head -n1 | cut -d ' ' -f 2`"
# Extract major and minor version numbers for numerical comparison
MAJOR=$(echo "$NVIM_VER" | sed -E 's/v([0-9]+)\..*/\1/')
MINOR=$(echo "$NVIM_VER" | sed -E 's/v[0-9]+\.([0-9]+).*/\1/')
# Only exit if version is truly less than 0.4.0
if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 4 ]; then exit 0; fi

killall -USR1 -u `whoami` nvim &>/dev/null
exit 0

