#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/message-api.env)
echo starting $NODE $0
sleep 5
env $(echo "$ENVSTR") $NODE -d 10 node_modules/message-api/lib/index.js | tee -a server.log
