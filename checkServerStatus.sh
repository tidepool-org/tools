#!/bin/bash

if [ /$1/ == /--nocolor/ ]; then
    RED=''
    GRN=''
    NOCOL=''
    shift
else
    RED='\x1b[22;31m'
    GRN='\x1b[22;32m'
    NOCOL='\x1b[0m'
fi

if [ /$1/ == // ]; then
    echo 'To check status, you need to specify local, devel, staging, or prod.'
    echo './checkStatus prod, for example'
    exit
else
    if [ $1 == 'local' ]; then
        API_URL='http://localhost:8009'
        UPLOAD_URL='http://localhost:9122'
        BLIP_URL='http://localhost:3000'
        CLAMSHELL_URL='http://localhost:3004'
    fi

    if [ $1 == 'devel' ]; then
        API_URL='https://devel-api.tidepool.io'
        UPLOAD_URL='https://devel-uploads.tidepool.io'
        BLIP_URL='https://blip-devel.tidepool.io'
        CLAMSHELL_URL='https://devel-clamshell.tidepool.io'
    fi

    if [ $1 == 'staging' ]; then
        API_URL='https://staging-api.tidepool.io'
        UPLOAD_URL='https://staging-uploads.tidepool.io'
        BLIP_URL='https://blip-staging.tidepool.io'
        CLAMSHELL_URL='https://staging-clamshell.tidepool.io'
    fi

    if [ $1 == 'prod' ]; then
        API_URL='https://api.tidepool.io'
        UPLOAD_URL='https://uploads.tidepool.io'
        BLIP_URL='https://blip-ucsf-pilot.tidepool.io'
        CLAMSHELL_URL='https://notes.tidepool.io'
    fi
fi


checkStatus() {
    server=$1
    url=$2
    response=$(curl --write-out %{http_code} --insecure --silent --output /dev/null $url)
    now=$(date "+%H:%M:%S")

    if [ $response == "200" ]; then
        COL=$GRN
        state='-good-'
    else
        COL=$RED
        state='*FAIL*'
    fi
    echo -e $now $COL$state$NOCOL response $COL $response $NOCOL -- $server
}


checkStatusThroughStyx() {
    server=$1
    styxpath=$2
    url=$API_URL/$styxpath/status
    checkStatus $server $url
}

# we can't check status of hakken because we have no route to it directly through styx
# we can't check status of styx directly, but if these things work then
# styx is functional

# for now, all we check is that these server endpoints return 200.
# we should probably do more.

checkStatusThroughStyx shoreline auth
checkStatusThroughStyx highwater metrics
checkStatusThroughStyx seagull metadata
checkStatusThroughStyx gatekeeper access
checkStatusThroughStyx hydrophone confirm
checkStatusThroughStyx message_api message
checkStatusThroughStyx tide-whisperer data
checkStatusThroughStyx octopus query
checkStatus jellyfish $UPLOAD_URL/status
checkStatus blip $BLIP_URL/index.html
checkStatus clamshell $CLAMSHELL_URL/index.html

