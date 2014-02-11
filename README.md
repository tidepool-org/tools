tools
=====

A place to put tooling and scripts that help when working on Tidepool stuff.

Contains:

## addLicense.py
addLicense.py is a script to add license text to a set of source files by searching for special markers in those files. 
It's reasonably smart. 
Run it with the -h switch for full help.

## extractDocs.py
extractDocs.py is designed to allow a natural form of documentation to be placed in source files that can then be extracted and
formatted appropriately for markdown files like the apiary documentation and also function-oriented docs like you'll find in
the *-client libraries.

It's driven by regular expressions and python's native formatting, which means the configuration file is a little cryptic. But it
was fast to implement and does the job of making it so that it's easier to keep code and docs in sync.

Once it's set up in a given repository, one merely has to run this to update the docs.

## runservers
This is a bash shell script to run a set of servers on localhost. We'll keep updating it as we grow.

