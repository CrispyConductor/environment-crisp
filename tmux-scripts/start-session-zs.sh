#!/bin/bash

SESS_NAME=zs

# check if session already exists
tmux has -t "$SESS_NAME" &>/dev/null
if [ $? -eq 0 ]; then echo 'Session already exists.'; exit 1; fi

# create session with initial window (notes)
tmux new -s "$SESS_NAME" -d -n 'notes'

# setup notes window
tmux send-keys -t "${SESS_NAME}:notes.0" 'cd ~/zipscene/notes' Enter 'nvim notes.txt' Enter

# setup cmd window
tmux neww -t "${SESS_NAME}" -c ~ -n 'cmd'
tmux splitw -t "${SESS_NAME}:cmd.0" -c ~ -v

# setup editor window
tmux neww -t "${SESS_NAME}" -c ~ -n 'edit'
tmux splitw -t "${SESS_NAME}:edit.0" -c ~ -v -l '10%'

# Set up window for ssh
tmux neww -t "${SESS_NAME}" -c ~ -n 'ssh'

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
tmux send-keys -t "${SESS_NAME}:procs.2" 'cd ~/zipscene/git/analytics-services-auth-service' Enter clear Enter 'NODE_ENV=local node bin/services-auth-service.js'
tmux send-keys -t "${SESS_NAME}:procs.3" 'cd ~/zipscene/git/analytics-services-job-hub' Enter clear Enter 'NODE_ENV=local node bin/services-job-hub.js'
tmux send-keys -t "${SESS_NAME}:procs.4" 'cd ~/zipscene/git/analytics-dmp-core' Enter clear Enter 'NODE_ENV=local node ./bin/dmp-core-api.js'
tmux send-keys -t "${SESS_NAME}:procs.5" 'cd ~/zipscene/git/analytics-dmp-core' Enter clear Enter 'NODE_ENV=local node ./bin/dmp-core-worker.js'

# Create alternate session
tmux new-session -s "${SESS_NAME}B" -t "$SESS_NAME" -d

# switch to default notes window
tmux select-window -t "${SESS_NAME}:0"

# attach to session
tmux a -t "$SESS_NAME"

