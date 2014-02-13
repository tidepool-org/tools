#!/bin/bash

. common
ENVSTR=$(load_env common.env message-api.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/message-api/lib/index.js 
