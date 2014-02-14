#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/user-api.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/user-api/lib/index.js 
