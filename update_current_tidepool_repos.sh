#! /bin/sh
# This script depends on a list of current repositories found in tools/current_repos.txt

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

update_one_tidepool_repo()
{
    echo "*** $1 ***"
    if [ ! -d "$1" ]; then
        echo "Cloning $1 because it seems to be missing."
        git clone https://github.com/tidepool-org/$1.git
    fi

    if [ -d "$1" ]; then
        cd $1
        git fetch --prune --tags
        git pull
        if [ -e package.json ]; then
            npm install
        fi
        if [ -e Comedeps ]; then
            ../tools/come_deps.sh
        fi
        cd ..
    fi
}

update_platform()
{
    echo "*** platform ***"
    export GOPATH=/tidepool/platform
    cd $GOPATH/src/github.com/tidepool-org/platform
    git fetch --prune --tags
    git pull
    . ./.env
    make build
}

for repo in $(cat "tools/required_repos.txt"); do
    update_one_tidepool_repo $repo
done

update_platform
