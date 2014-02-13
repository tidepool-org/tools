#!/bin/bash

. common
ENVSTR=$(load_env common.env seagull.env)
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE node_modules/seagull/lib/index.js 
