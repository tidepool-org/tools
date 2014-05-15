tools
=====

A place to put tooling and scripts that help when working on Tidepool stuff.

Contains:

## required_repos.txt
This is just a list of the names of required repositories if you're going to run the Tidepool stack locally. It's used by the following two scripts.

## get_current_tidepool_repos.sh
This is a script that will clone all the required repositories into a directory structure expected by runservers and the update script. It also runs npm install and bower install appropriately.

## update_current_tidepool_repos.sh
This is a script that will fetch latest changes and update npm and bower for all the repositories listed in required_repos.txt.

## runservers
This is a script to run a set of servers on localhost. Note that it's not executable -- that's because you shouldn't run it directly -- use "source" (also known as ".") to run it, as in ```. tools/runservers``` We'll keep updating it as we grow.

## addLicense.py
addLicense.py is a script to add license text to a set of source files by searching for special markers in those files. 
It's reasonably smart. 
Run it with the -h switch for full help.

## extractDocs.py
THIS IS EXPERIMENTAL
extractDocs.py is designed to allow a natural form of documentation to be placed in source files that can then be extracted and
formatted appropriately for markdown files like the apiary documentation and also function-oriented docs like you'll find in
the *-client libraries.

It's driven by regular expressions and python's native formatting, which means the configuration file is a little cryptic. But it
was fast to implement and does the job of making it so that it's easier to keep code and docs in sync.

Once it's set up in a given repository, one merely has to run this to update the docs.

