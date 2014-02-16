#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/user-api.env)
echo starting $NODE $0
sleep 5
env $(echo "$ENVSTR") $NODE -d 10 node_modules/user-api/lib/index.js | tee -a server.log
