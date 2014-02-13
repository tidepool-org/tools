#!/bin/bash

. common
ENVSTR=$(load_env common.env)
echo starting $NODE $0
export HTTP_PORT=8009
export ANNOUNCE_HOST="localhost"
export RULES="\
{\
  \"localhost:8009\": [{ \"type\": \"cors\",\
                         \"headers\": {\
                           \"access-control-allow-origin\": \"*\",\
         \"access-control-allow-headers\": \"authorization, content-type, x-tidepool-session-token\",\
                           \"access-control-allow-methods\": \"GET, POST, PUT\",\
                           \"access-control-expose-headers\": \"x-tidepool-session-token\",\
                           \"access-control-max-age\": 0
                         }\
                       },\
                       {\"type\": \"pathPrefix\", \"prefix\": \"/auth\", \"rule\": {\"type\": \"random\", \"service\": \"user-api-local\"}},\
                       {\"type\": \"pathPrefix\", \"prefix\": \"/group\", \"rule\": {\"type\": \"random\", \"service\": \"armada-local\"}},\
                       {\"type\": \"pathPrefix\", \"prefix\": \"/message\", \"rule\": {\"type\": \"random\", \"service\": \"message-api-local\"}},\
                       {\"type\": \"pathPrefix\", \"prefix\": \"/metadata\", \"rule\": {\"type\": \"random\", \"service\": \"seagull-local\"}}]\
}"
export DISCOVERY="\
{\
  \"host\": \"localhost:8000\"\
}"
env $(echo "$ENVSTR") $NODE ./node_modules/.bin/tidepool-coordinator
