#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/hakken.env)
echo $ANNOUNCE_HOST
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE ./node_modules/hakken/coordinator.js
