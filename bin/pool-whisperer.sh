#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/pool-whisperer.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/pool-whisperer/server.js
