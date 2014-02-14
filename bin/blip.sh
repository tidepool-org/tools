#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/blip/develop.js
