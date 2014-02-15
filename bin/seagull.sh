#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/seagull.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/seagull/lib/index.js | tee server.log
