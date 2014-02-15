#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/jellyfish.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/jellyfish/app.js 2>&1 | tee server.log
