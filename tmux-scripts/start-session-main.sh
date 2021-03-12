#!/bin/bash

SESS_NAME=main

# check if session already exists
tmux has -t "$SESS_NAME" &>/dev/null
if [ $? -eq 0 ]; then echo 'Session already exists.'; exit 1; fi

# create session with initial window (notes)
tmux new -s "$SESS_NAME" -d -n 'notes'

# setup notes window
tmux send-keys -t "${SESS_NAME}:notes.0" 'cd ~/git/misc-text-files' Enter 'nvim notes.txt' Enter

# setup cmd window
tmux neww -t "${SESS_NAME}" -c ~ -n 'cmd'
tmux splitw -t "${SESS_NAME}:cmd.0" -c ~ -v

# setup editor window
tmux neww -t "${SESS_NAME}" -c ~ -n 'edit'
tmux splitw -t "${SESS_NAME}:edit.0" -c ~ -v -l '10%'
#tmux send-keys -t "${SESS_NAME}:edit.0" 'nvim' Enter ':NERDTree' Enter

# setup workmac window
tmux neww -t "${SESS_NAME}" -c ~ -n 'workmac'
tmux send-keys -t "${SESS_NAME}:workmac.0" 'clipssh cb185222@workmac' Enter

# setup hedron window
tmux neww -t "${SESS_NAME}" -c ~ -n 'hedron'
tmux send-keys -t "${SESS_NAME}:hedron.0" 'clipssh cbreneman@hedron.landofcrispy.com' Enter

# select default window
tmux select-window -t "${SESS_NAME}:0"

# Create alternate session
tmux new-session -s "${SESS_NAME}B" -t "$SESS_NAME" -d

# attach to session
tmux a -t "$SESS_NAME"

