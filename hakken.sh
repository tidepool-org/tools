#!/bin/bash

. common
ENVSTR=$(load_env common.env hakken.env)
echo $ANNOUNCE_HOST
echo starting $NODE $0
env $(echo "$ENVSTR") $NODE ./node_modules/.bin/tidepool-coordinator
