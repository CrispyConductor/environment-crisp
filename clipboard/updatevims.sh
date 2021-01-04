#!/bin/bash

# Sends USR1 signal to running vims to cause them to pull in a clipboard update

killall -USR1 -u `whoami` nvim vim &>/dev/null
exit 0

