#!/bin/bash
ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/armada.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/group-api/lib/index.js 
