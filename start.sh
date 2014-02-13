#!/bin/bash

. common

mkdir -p run 
./node_modules/.bin/nf -e common.env start
