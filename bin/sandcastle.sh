#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/sandcastle.env)
echo starting $NODE $0
export BASE="$(pwd)/$BASE"
echo "USING $BASE"
(env $(echo "$ENVSTR") $NODE node_modules/sandcastle/server.js 2>&1 ) | tee server.log
