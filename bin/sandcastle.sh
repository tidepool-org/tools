#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/sandcastle.env)
echo starting $NODE $0
export BASE="$(pwd)/$BASE"
echo "USING $BASE"
sleep 5
env $(echo "$ENVSTR") BASE="$BASE" $NODE node_modules/sandcastle/server.js | tee -a server.log
