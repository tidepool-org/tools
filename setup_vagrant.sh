#!/bin/bash

echo "Adding MongoDB Repository"
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D68FA50FEA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

echo "Perform Update"
apt-get update

echo "Installing htop..."
apt-get install -y htop

echo "Installing zip (needed for Chrome Uploader builds)..."
apt-get install -y zip unzip

echo "Installing node.js..."
wget -qO- http://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz  | tar -C /usr/local --strip-components 1 -xzv

echo "Installing PhantomJS..."
# Installation of PhantomJS taken from https://gist.github.com/julionc/7476620
apt-get install -y build-essential chrpath libssl-dev libxft-dev
sudo apt-get install -y libfreetype6 libfreetype6-dev
sudo apt-get install -y libfontconfig1 libfontconfig1-dev

cd ~
export PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"
wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2
sudo tar xvjf $PHANTOM_JS.tar.bz2

sudo mv $PHANTOM_JS /usr/local/share
sudo ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin

echo "Installing Gulp..."
npm install --global gulp
npm install --save-dev gulp

echo "Installing Mocha..."
npm install -g mocha

echo "Installing Webpack..."
npm install -g webpack

echo "Installing MongoDB..."
apt-get install -y mongodb-org=3.2.11 mongodb-org-server=3.2.11 mongodb-org-shell=3.2.11 mongodb-org-mongos=3.2.11 mongodb-org-tools=3.2.11

echo "Installing golang..."
wget -qO- https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz | tar -C /usr/local/ -xzv
# Set PATH variable for Go
echo "export PATH=\$PATH:/usr/local/go/bin" > /etc/profile.d/golang.sh
echo "export GOPATH=/tidepool/platform" >> /etc/profile.d/golang.sh

# Reload bash profile so that go is present on PATH
source ~/.profile
source /etc/profile

echo "Installing bzr..."
apt-get install -y bzr

echo "Cloning tidepool-tools..."
pushd /tidepool
if [ -d "tools" ]; then
    echo "Skipping, because there is already a directory by that name."
else
    git clone https://github.com/tidepool-org/tools.git
fi
popd

echo "Doing initial checkout..."
cd /tidepool/tools
sh ./get_current_tidepool_repos.sh

# Add some convenient aliases for tidepool
echo "alias tidepool-runservers='cd /tidepool/ && . tools/runservers'" > /etc/profile.d/tidepool.sh
echo "alias tidepool-update='cd /tidepool/tools && sh ./update_current_tidepool_repos.sh'" >> /etc/profile.d/tidepool.sh
