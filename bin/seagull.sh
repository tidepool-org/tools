#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/seagull.env)
echo starting $NODE $0
sleep 5
env $(echo "$ENVSTR") $NODE node_modules/seagull/lib/index.js | tee -a server.log
