tools
=====

A place to put tooling and scripts that help when working on Tidepool stuff.

Contains:

## required_repos.txt
This is just a list of the names of required repositories if you're going to run the Tidepool stack locally. It's used by the following two scripts.

## get_current_tidepool_repos.sh
This is a script that will clone all the required repositories into a directory structure expected by runservers and the update script. It also runs npm install and bower install appropriately. It first checks that you have several required tools installed.

## update_current_tidepool_repos.sh
This is a script that will fetch latest changes and update npm and bower for all the repositories listed in required_repos.txt.

## status.sh
This is a script that returns a (colorized) status of the state of git for a collection of repositories (either the required ones only, or all the repositories that are siblings of this one). It's handy for keeping track of changes in flight.

## runservers
This is a script to run a set of servers on localhost. Note that it's not executable -- that's because you shouldn't run it directly -- use "source" (also known as ".") to run it, as in ```. tools/runservers``` We'll keep updating it as we grow.

## checkServerStatus.sh
This is a script that pings all the running servers for a particular deploy (local, dev, stg, or prd). It prints out a colorized status for them all.

## addLicense.py
addLicense.py is a script to add license text to a set of source files by searching for special markers in those files.
It's reasonably smart.
Run it with the -h switch for full help.

## groupedit

Please see the README in the groupedit repository.

## extractDocs.py
THIS IS EXPERIMENTAL AND WAS NEVER FINISHED

extractDocs.py is designed to allow a natural form of documentation to be placed in source files that can then be extracted and
formatted appropriately for markdown files like the apiary documentation and also function-oriented docs like you'll find in
the *-client libraries.

It's driven by regular expressions and python's native formatting, which means the configuration file is a little cryptic. But it
was fast to implement and does the job of making it so that it's easier to keep code and docs in sync.

Once it's set up in a given repository, one merely has to run this to update the docs.

## Development VM using Vagrant

Tidepool has a VM for quickly firing up a development environment on your local machine.

The Vagrant configuration creates a VM and checks out all of the Tidepool repositories to get you developing on [Tidepool](http://tidepool.org) as quickly as possible.

#### Prerequisites
To use this `Vagrantfile`, you need to have [Vagrant](https://www.vagrantup.com/) installed, as well as one of the following VM providers:
* [VirtualBox](https://www.virtualbox.org/) (Windows, Mac OS X and Linux)
* [Parallels](http://www.parallels.com/) (Mac OS X only)
* [VMware Fusion](https://www.vmware.com/products/fusion) (Mac OS X) or [VMware Workstation](http://www.vmware.com/products/workstation) (Windows, Linux) with the [Vagrant VMware Provider](https://www.vagrantup.com/vmware) (Windows, Mac OS X, Linux)

#### To get started
* Create a top level tidepool directory somewhere (eg `tidepool`)
* Clone this repo into a subdirectory called `tools`
* Open a console, and change into the cloned `tools` directory
* Run `vagrant up --provider <Provider Name>`, where `<Provider Name>` is one of:
  * `virtualbox`
  * `parallels`
  * `vmware_desktop`

This will download and install the Base Ubuntu 14.04 virtual machine and install the following Tidepool dependencies:
* Node.js v0.12.7
* Gulp
* Mocha
* MongoDB 3.2.11
* golang 1.7.1
* bzr

Once the box has been set up, you can ssh into it using:
```
# vagrant ssh
```

This box also has some convenience aliases to help with development:
```
# tidepool-runservers # <-- Starts the tidepool servers
# tidepool-update     # <-- Fetches the latest changes and updates npm/bower
```
