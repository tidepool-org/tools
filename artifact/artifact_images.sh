#!/bin/sh -eu

# get diabeloop images

wget -v -O favicon.ico 'https://raw.githubusercontent.com/mdblp/tools/feature/add-diabeloop-images/artifact/images/favicon.ico'

wget -v -O logo.png 'https://raw.githubusercontent.com/mdblp/tools/feature/add-diabeloop-images/artifact/images/logo.png'

if [ ! -d app/components/navbar/images/diabeloop ]; then
    mkdir app/components/navbar/images/diabeloop
fi
cp logo.png app/components/navbar/images/diabeloop
if [ ! -d app/components/loginlogo/images/diabeloop ]; then
    mkdir app/components/loginlogo/images/diabeloop
fi
mv logo.png app/components/loginlogo/images/diabeloop/
