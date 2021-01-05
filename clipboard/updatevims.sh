#!/bin/bash

# Sends USR1 signal to running nvims to cause them to pull in a clipboard update

# Make sure nvim exists
if ! command -v nvim &>/dev/null; then exit 0; fi

# If nvim version is too old, it may crash on USR1, so don't try it
NVIM_VER="`nvim -v | grep '^NVIM' | head -n1 | cut -d ' ' -f 2`"
if [[ "$NVIM_VER" < "v0.4" ]]; then exit 0; fi

killall -USR1 -u `whoami` nvim &>/dev/null
exit 0

