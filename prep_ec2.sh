# This script installs the runtime environments (node, go, etc) needed for Tidepool to run on Amazon linux
# The script can be run on a fresh EC2 instance (Amazon Linux) prior to running 'tools/get_current_tidepool_repos.sh'
# and tools/runservers
# Intended for dev/testing only - not for production

# Install git
sudo yum install git

#install node
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash
source /home/ec2-user/.bashrc 
nvm install node 5.1.0
echo 'nvm use 5.1.0' >> /home/ec2-user/.bashrc

# Install dev tools (required for some node modules)
sudo yum install gcc gcc-c++ autoconf automake

#install and start MongoDB
echo "[MongoDB]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64
gpgcheck=0
enabled=1" | sudo tee -a /etc/yum.repos.d/mongodb.repo

sudo yum install -y mongodb-org-server mongodb-org-shell mongodb-org-tools
sudo service mongod start


#install required node modules
npm install --global gulp
npm install --global mocha
npm install --global node-libs-browser

# Install Golang
sudo wget https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz
tar -xzf go1.4.2.linux-amd64.tar.gz 
echo 'export GOROOT=/home/ec2-user/go' >> /home/ec2-user/.bashrc
echo 'export PATH=$PATH:$GOROOT/bin' >> /home/ec2-user/.bashrc
echo 'export GOBIN=$GOROOT/bin' >> /home/ec2-user/.bashrc

# Install bzr
sudo yum install bzr --enablerepo=epel

# clone the tidepool tools repository
git clone https://github.com/tidepool-org/tools.git


