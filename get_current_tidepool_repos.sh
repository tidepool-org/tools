#! /bin/bash
# This script depends on a list of current repositories found in tools/current_repos.txt
# it checks a few requirements before running

require()
{
    hash $1 2>/dev/null || { "You must have $1 available on your executable path. $2" ; exit 1; }
}

require git "Visit git-scm.com to get it."
require node "Visit nodejs.org to get it."
require npm "Visit npmjs.org to get it."
require gulp "Use 'npm install --global gulp' to get it."
require mocha "Use 'npm install --global mocha' to get it."
require cc "On a Mac, install XCode and its command line tools."
require mongod "Visit mongodb.org/.  Or, on a Mac, use 'brew install mongodb'."
require go "Visit golang.org to get it."
require bzr "Visit http://bazaar.canonical.com/ to get it.  Or, on a Mac, just use brew install bzr"

if [ -f runservers ]; then
  cd ..
fi

if [ ! -d tools ]; then
  echo "You should be in the tools directory or its immediate parent directory to run this."
  exit 1
fi

get_one_tidepool_repo()
{
    echo "*** $1 ***"
    if [ -d "$1" ]; then
        echo "Skipping $1 because there is already a directory by that name."
    else
        git clone https://github.com/tidepool-org/$1.git
        cd $1
        if [ -f package.json ]; then
            npm install
        fi
        cd ..
    fi
}

for i in $(cat "tools/required_repos.txt"); do
    get_one_tidepool_repo $repo
done

