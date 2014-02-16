#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/sandcastle.env)
echo starting $NODE $0
export BASE="$(pwd)/persist/sandcastle"
echo "USING $BASE"
mkdir -p $BASE
sleep 5
env $(echo "$ENVSTR") BASE="$BASE" $NODE -d 5 node_modules/sandcastle/server.js | tee -a server.log
