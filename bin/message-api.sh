#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/message-api.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/message-api/lib/index.js 
