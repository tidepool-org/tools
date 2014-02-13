#!/bin/bash

. common
ENVSTR=$(load_env common.env sandcastle.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/sandcastle/server.js
