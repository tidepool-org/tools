#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/sandcastle.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/sandcastle/server.js
