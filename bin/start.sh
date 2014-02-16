#!/bin/bash

export TIDEPOOL_HOME=$(pwd)
export ETC="$TIDEPOOL_HOME/etc"
export BIN="$TIDEPOOL_HOME/bin"
echo $TIDEPOOL_HOME
echo $ETC
echo $BIN
. $BIN/common

export PATH=$PATH:$TIDEPOOL_HOME/bin
mkdir -p run 
export TIDEPOOL_HOME ETC BIN
./node_modules/.bin/nf -e $ETC/common.env start
