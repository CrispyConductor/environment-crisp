#!/bin/sh

# If a new tmux buffer has been created recently, return the contents

# buffer must have been created within this number of seconds
MAX_TIME_DIFF=3
# don't output if buffer too large
MAX_SIZE=100000000

# this line uses tmux's built-in filtering which is only available in bleeding versions
#csv="`tmux list-buffers -F '#{buffer_created},#{buffer_size},#{buffer_name}' -f '#{m:buffer*,#{buffer_name}}'`"
csv="`tmux list-buffers -F '#{buffer_created},#{buffer_size},#{buffer_name}' | grep ',buffer[0-9]'`"
if [ $? -ne 0 ]; then exit 1; fi
csv="`echo "$csv" | head -n1`"
if [ -z "$csv" ]; then exit 1; fi

ctime="`echo "$csv" | cut -d , -f 1`"
bsize="`echo "$csv" | cut -d , -f 2`"
bname="`echo "$csv" | cut -d , -f 3-`"
now="`date +%s`"

if [ `expr $now - $ctime` -gt $MAX_TIME_DIFF ]; then exit 1; fi
if [ $bsize -gt $MAX_SIZE ]; then exit 1; fi

tmux show-buffer -b "$bname"


