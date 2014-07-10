#! /bin/bash

# usage: addToCareteam.sh staging a@a.com b@b.com
# this put's b on a's careteam, and puts a on b's patients list.

if [ ! -e config/$1.json ]; then
    echo "config/$1.json doesn't exist"
else
    if lib/tidepool-pwreset.js --config=$1 --user=$2; then
        if lib/tidepool-pwreset.js --config=$1 --user=$3; then
            if lib/tidepool-groupedit.js --config=$1 --group=team  --user=$2 --add $3; then
                echo "Added $3 to group 'team' of $2"
            fi
            if lib/tidepool-groupedit.js --config=$1 --group=patients --user=$3 --add $2; then
                echo "Added $2 to group 'patients' of $3"
            fi
        fi
    fi
fi
