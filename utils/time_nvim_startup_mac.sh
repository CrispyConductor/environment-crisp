#!/bin/bash

CFG=~/.config/nvim/init.vim

if [ ! -f $CFG ]; then exit 1; fi
cp $CFG /tmp/cfg-bak

echo 'autocmd VimEnter * :q!' >> $CFG

SUM=0
CNT=0

for ((c=0; c<=20; c++)); do
	/usr/bin/time -p nvim >/dev/null 2>/tmp/ttout
	SECS=`cat /tmp/ttout | grep real | awk '{print $2}'`
	SUM=`echo $SUM + $SECS | bc -l`
	CNT=`expr $CNT + 1`
done

AVG=`echo $SUM / $CNT | bc -l`
echo $AVG

mv /tmp/cfg-bak $CFG


