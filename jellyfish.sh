#!/bin/bash

. common
ENVSTR=$(load_env common.env jellyfish.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/jellyfish/app.js
