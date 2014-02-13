#!/bin/bash

. common
ENVSTR=$(load_env common.env armada.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/group-api/lib/index.js 
