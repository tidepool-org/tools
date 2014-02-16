#!/bin/bash

tidepool-services-ls.sh | while read PROJECT ; do
  ./git-npm-sibling-link $PROJECT
done

