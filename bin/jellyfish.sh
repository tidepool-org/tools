#!/bin/bash

ETC="./etc"
. bin/common
ENVSTR=$(load_env $ETC/common.env $ETC/jellyfish.env)
echo starting $NODE $0
sleep 5
env $(echo "$ENVSTR") $NODE node_modules/jellyfish/app.js
