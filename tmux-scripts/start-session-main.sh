#!/bin/bash

SESS_NAME=main

# check if session already exists
tmux has -t "$SESS_NAME" &>/dev/null
if [ $? -eq 0 ]; then echo 'Session already exists.'; exit 1; fi

# create session with initial window (notes)
tmux new -s "$SESS_NAME" -d -n 'notes'

# global options
#tmux setw -g -t "$SESS_NAME" mode-keys vi  # should be in tmux.conf

# setup notes window
tmux send-keys -t "${SESS_NAME}:notes.0" 'cd ~/git/misc-text-files' Enter 'nvim notes.txt' Enter

# setup editor window
tmux neww -t "${SESS_NAME}" -c ~ -n 'edit'
tmux splitw -t "${SESS_NAME}:edit.0" -c ~ -v -l '10%'
tmux send-keys -t "${SESS_NAME}:edit.0" 'nvim' Enter ':NERDTree' Enter

# setup cmd0 window
tmux neww -t "${SESS_NAME}" -c ~ -n 'cmd0'
tmux splitw -t "${SESS_NAME}:cmd0.0" -c ~ -v

# setup workmac window
tmux neww -t "${SESS_NAME}" -c ~ -n 'workmac'
tmux send-keys -t "${SESS_NAME}:workmac.0" 'ssh cb185222@workmac' Enter 'tmux a -t zs' Enter

# select default window
tmux select-window -t "${SESS_NAME}:0"

# attach to session
tmux a -t "$SESS_NAME"

