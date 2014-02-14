#!/bin/bash

tidepool-services-ls.sh | while read PROJECT ; do
   clone-sibling.sh $PROJECT
done

