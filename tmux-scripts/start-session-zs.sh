#!/bin/bash

SESS_NAME=zs

# check if session already exists
tmux has -t "$SESS_NAME" &>/dev/null
if [ $? -eq 0 ]; then echo 'Session already exists.'; exit 1; fi

# create session with initial window (notes)
tmux new -s "$SESS_NAME" -d -n 'notes'

# global options
tmux setw -g -t "$SESS_NAME" mode-keys vi

# set up notes window
tmux send-keys -t "${SESS_NAME}:notes.0" 'cd ~/zipscene/notes' Enter 'vim notes.txt' Enter

# create window for running processes
# panes are: zookeeper, kafka, authservice, jobhub, api, worker
# prefill but don't execute commands
tmux neww -t "${SESS_NAME}" -n 'procs'
tmux splitw -t "${SESS_NAME}:procs.0"
tmux select-layout -t "${SESS_NAME}:procs" tiled
tmux splitw -t "${SESS_NAME}:procs.0"
tmux select-layout -t "${SESS_NAME}:procs" tiled
tmux splitw -t "${SESS_NAME}:procs.0"
tmux select-layout -t "${SESS_NAME}:procs" tiled
tmux splitw -t "${SESS_NAME}:procs.0"
tmux select-layout -t "${SESS_NAME}:procs" tiled
tmux splitw -t "${SESS_NAME}:procs.0"
tmux select-layout -t "${SESS_NAME}:procs" tiled
tmux send-keys -t "${SESS_NAME}:procs.0" 'cd ~/zipscene/kafka_*' Enter clear Enter './bin/zookeeper-server-start.sh config/zookeeper.properties'
tmux send-keys -t "${SESS_NAME}:procs.1" 'cd ~/zipscene/kafka_*' Enter clear Enter './bin/kafka-server-start.sh config/server.properties'
tmux send-keys -t "${SESS_NAME}:procs.2" 'cd ~/zipscene/git/zs-auth-service' Enter clear Enter 'NODE_ENV=local node bin/zs-auth-service.js'
tmux send-keys -t "${SESS_NAME}:procs.3" 'cd ~/zipscene/git/zs-job-hub' Enter clear Enter 'NODE_ENV=local node bin/zs-job-hub.js'
tmux send-keys -t "${SESS_NAME}:procs.4" 'cd ~/zipscene/git/zs-dmp' Enter clear Enter 'NODE_ENV=local node ./bin/zs-dmp-api.js'
tmux send-keys -t "${SESS_NAME}:procs.5" 'cd ~/zipscene/git/zs-dmp' Enter clear Enter 'NODE_ENV=local node ./bin/zs-dmp-worker.js'

# dmp tests window
tmux neww -t "$SESS_NAME" -n 'dmptests'
tmux send-keys -t "${SESS_NAME}:dmptests.0" 'cd ~/zipscene/git/zs-dmp-tests' Enter clear Enter 'npm test'

# cmd0 window
tmux neww -t "$SESS_NAME" -n 'cmd0' -c ~

# switch to default notes window
tmux select-window -t "${SESS_NAME}:0"

# attach to session
tmux a -t "$SESS_NAME"

