#!/bin/bash



# The UI clip sync daemon will automatically poll and handle this, but also
# send it a signal to speed it up.
SYNCPID="`ps aux | grep uiclipsyncd | grep python | grep -v grep | awk '{print $2}'`"
if [ "$SYNCPID" != "" ]; then
	kill -s HUP "$SYNCPID" &>/dev/null
fi


