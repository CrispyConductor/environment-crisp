#!/bin/bash

if [ $# -lt 1 ]; then echo "Supply session name."; exit 1; fi

SESS_NAME="$1"

# check if session already exists
tmux has -t "$SESS_NAME" &>/dev/null
if [ $? -eq 0 ]; then echo 'Session already exists.'; exit 1; fi

# create session with initial window (notes)
tmux new -s "$SESS_NAME" -d

# global options
tmux setw -g -t "$SESS_NAME" mode-keys vi

# attach to session
tmux a -t "$SESS_NAME"

