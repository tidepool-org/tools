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
    echo 'To check status, you need to specify local, dev, stg, or prd.'
    echo './checkStatus prd, for example'
    exit
else
    if [ $1 == 'local' ]; then
        API_URL='http://localhost:8009'
        UPLOAD_URL='http://localhost:9122'
        BLIP_URL='http://localhost:3000'
    fi

    if [ $1 == 'dev' ]; then
        API_URL='https://dev-api.tidepool.org'
        UPLOAD_URL='https://dev-uploads.tidepool.org'
        BLIP_URL='https://dev-blip.tidepool.org'
    fi

    if [ $1 == 'stg' ]; then
        API_URL='https://stg-api.tidepool.org'
        UPLOAD_URL='https://stg-uploads.tidepool.org'
        BLIP_URL='https://stg-blip.tidepool.org'
    fi

    if [ $1 == 'prd' ]; then
        API_URL='https://api.tidepool.org'
        UPLOAD_URL='https://uploads.tidepool.org'
        BLIP_URL='https://blip.tidepool.org'
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
checkStatus jellyfish $UPLOAD_URL/status
checkStatus blip $BLIP_URL/index.html
