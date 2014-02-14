#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env)
echo starting $NODE $0
# export HTTP_PORT=8009
export HTTP_PORT=$PORT
export ANNOUNCE_HOST="localhost"
export RULES=`cat styx_rules.json`
export DISCOVERY="\
{\
  \"host\": \"localhost:8000\"\
}"
env $(echo "$ENVSTR") $NODE ./node_modules/styx/server.js
