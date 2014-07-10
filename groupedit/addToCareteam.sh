#! /bin/bash

# usage: addToCareteam.sh staging a@a.com b@b.com
# this put's b on a's careteam, and puts a on b's patients list.

if [ ! -e config/$1.json ]; then
    echo "config/$1.json doesn't exist"
else
    node lib/zuul.js -c $1 $2 add $3
fi
