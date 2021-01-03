#!/bin/sh

# Sends USR1 signal to running vims to cause them to pull in a clipboard update

killall -q -s USR1 -u `whoami` nvim vim

