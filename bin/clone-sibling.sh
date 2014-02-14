#!/bin/bash

PROJECT=$1
REPO_URL=git@github.com:tidepool-org/$PROJECT.git
( cd ..
git clone $REPO_URL
)

