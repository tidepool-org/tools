#! /bin/sh
# This script depends on a list of current repositories found in tools/current_repos.txt

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

repos=( $(cat "tools/required_repos.txt") )  #  Stores contents of that file in an array.

update_one_tidepool_repo()
{
    echo "*** $1 ***"
    if [ ! -d "$1" ]; then
        echo "Cloning $1 because it seems to be missing."
        git clone git@github.com:tidepool-org/$1.git
    fi

    if [ -d "$1" ]; then
        cd $1
        git fetch --prune --tags
        git pull
        if [ -f package.json ]; then
            npm install
        fi
        if [ -f bower.json ]; then
            bower install
        fi
        cd ..
    fi
}

for elt in $(seq 0 $((${#repos[@]} - 1))); do
    update_one_tidepool_repo ${repos[$elt]}
done
