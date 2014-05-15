#! /bin/sh
# This script depends on a list of current repositories found in tools/current_repos.txt

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit(1)
fi

repos=( $(cat "tools/required_repos.txt") )  #  Stores contents of that file in an array.


get_one_tidepool_repo()
{
    echo "*** $1 ***"
    if [ -d "$1" ]; then
        echo "Skipping $1 because there is already a directory by that name."
    else
        git clone git@github.com:tidepool-org/$1.git
        cd $1
        if [ -f package.json ]; then
            npm install
        fi
        if [ -f bower.json ]; then
            bower install
        fi
    fi
}

for elt in $(seq 0 $((${#repos[@]} - 1))); do
    get_one_tidepool_repo ${repos[$elt]}
done
