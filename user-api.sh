#!/bin/bash

. common
ENVSTR=$(load_env common.env user-api.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/user-api/lib/index.js 
