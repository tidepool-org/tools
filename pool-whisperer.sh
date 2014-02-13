#!/bin/bash

. common
ENVSTR=$(load_env common.env pool-whisperer.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/pool-whisperer/server.js
