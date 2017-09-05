tools
=====

A place to put tooling and scripts that help when working on Tidepool stuff.

Contains:

## required_repos.txt
This is just a list of the names of required repositories if you're going to run the Tidepool stack locally. It's used by the following two scripts. It does not include the Go repos.

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

## Docker development environment
Tidepool has a [Docker](https://www.docker.com/what-docker) environment that lets you quickly spin up a whole Tidepool environment to test and see how it works.
If you're developing, you can then optionally clone the git projects you want to work with, and attach your local git workspace to the relevant container.

#### Prerequisites
To get started, [download Docker CE for your operating system](https://www.docker.com/community-edition#/download) and install it.

#### To get started
* Create a top level tidepool directory somewhere (eg `tidepool`)
* Download the [`docker-compose.yml`](https://raw.githubusercontent.com/tidepool-org/tools/master/docker-compose.yml) file into the directory
  * Alternatively if you're developing, you might choose to download or clone the `tools` repo into the top level directory
* Open a console, and change into the directory where the `docker-compose.yml` is located
* Run `docker-compose up`

`docker-compose` will download and run all of the Tidepool microservices.
Once the services are running, you can navigate to http://localhost:3000 to start interacting with the Tidepool Web App.
When you have finished using the environment, you can press `CTRL + C` to shutdown the Docker containers.

#### List of Tidepool Docker containers
| Container name            | Purpose                                             | GitHub repository                                 | Optional Environment variables                                                           |
|---------------------------|-----------------------------------------------------|---------------------------------------------------|------------------------------------------------------------------------------------------|
| `mongo`                   | MongoDB for data storage                            | Instance of the standard MongoDB Docker container | `TP_MONGO_DATA_DIR`: local directory to store MongoDB data files                         |
| `tidepool/blip`           | The Tidepool Web App                                | https://github.com/tidepool-org/blip              | `TP_BLIP_DIR`: local directory where the `blip` repository is cloned                     |
| `tidepool/viz` (optional) | The Tidepool Viz App                                | https://github.com/tidepool-org/viz               | `TP_VIZ_DIR`: local directory where the `viz` repository is cloned                     |
| `tidepool/dataservices`   | Current generation upload service                   | https://github.com/tidepool-org/platform          | `TP_PLATFORM_DIR`: local directory where the `platform` repository is cloned             |
| `tidepool/gatekeeper`     | Authorization client and server for tidepool        | https://github.com/tidepool-org/gatekeeper        | `TP_GATEKEEPER_DIR`: local directory where the `gatekeeper` repository is cloned         |
| `tidepool/hakken`         | Discovery service                                   | https://github.com/tidepool-org/hakken            | `TP_HAKKEN_DIR`: local directory where the `hakken` repository is cloned                 |
| `tidepool/highwater`      | Metrics reporting service                           | https://github.com/tidepool-org/highwater         | `TP_HIGHWATER_DIR`: local directory where the `highwater` repository is cloned           |
| `tidepool/hydrophone`     | Notification service (sending reminder emails, etc) | https://github.com/tidepool-org/hydrophone        | `TP_HYDROPHONE_DIR`: local directory where the `hydrophone` repository is cloned         |
| `tidepool/jellyfish`      | Legacy upload service                               | https://github.com/tidepool-org/jellyfish         | `TP_JELLYFISH_DIR`: local directory where the `jellyfish` repository is cloned           |
| `tidepool/message-api`    | Message service for adding context to diabetes data | https://github.com/tidepool-org/message-api       | `TP_MESSAGE_API_DIR`: local directory where the `message-api` repository is cloned       |
| `tidepool/seagull`        | User metadata service                               | https://github.com/tidepool-org/seagull           | `TP_SEAGULL_DIR`: local directory where the `seagull` repository is cloned               |
| `tidepool/shoreline`      | Legacy authorization service                        | https://github.com/tidepool-org/shoreline         | `TP_SHORELINE_DIR`: local directory where the `shoreline` repository is cloned           |
| `tidepool/styx`           | Routing and load balancing service                  | https://github.com/tidepool-org/styx              | `TP_STYX_DIR`: local directory where the `styx` repository is cloned                     |
| `tidepool/tide-whisperer` | Data access API                                     | https://github.com/tidepool-org/tide-whisperer    | `TP_TIDE_WHISPERER_DIR`: local directory where the `tide-whisperer` repository is cloned |
| `tidepool/userservices`   | Current generation authorization service            | https://github.com/tidepool-org/platform          | `TP_PLATFORM_DIR`: local directory where the `platform` repository is cloned             |

#### Working with Tidepool Docker containers
| Use command...                | When you want to                                                                                                                                |
|-------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `docker-compose up`           | start up the containers in interactive mode (shows logs). Press `CTRL + C` to exit                                                              |
| `docker-compose up -d`        | start up the containers in non-interactive mode                                                                                                 |
| `docker-compose ps`           | show the list of running Tidepool containers                                                                                                    |
| `docker-compose down`         | shut down the containers, and remove the virtual networks                                                                                       |
| `docker-compose logs`         | shows logs for all of the containers                                                                                                            |
| `docker-compose logs blip`    | shows logs for just the `blip` container. Use different container names to see other logs                                                       |
| `docker-compose logs -f styx` | shows logs for just the `styx` container, and follows the log output (similar to `tail -f`). Use different container names to follow other logs |
| `docker-compose pull`         | download the latest versions of the Tidepool Docker containers (run `docker-compose up -d` afterwards to apply the updates)                     |

#### Developing with the Docker containers
To develop for Tidepool using the Docker containers, you should first clone the repositories that you wish to contribute to.
Developing for golang-based services is different for developing for Node-based services.
There are 5 go-based services in Tidepool: `hydrophone`, `shoreline`, `tide-whisperer`, `dataservices` and `userservices` (the last 2 are part of the `platform` repository).

##### Golang-based containers
To prepare your repository clone for development:
* In a terminal window, make sure that you're in the same directory as the `docker-compose.yml` file.
* Set the optional Environment Variable for the repository you're working on.
  * If you were working on `dataservices`, you would `export TP_PLATFORM_DIR=<Full path to platform clone>`, for example `export TP_PLATFORM_DIR=$PWD/platform`
* Edit the `docker-compose.yml`, and un-comment  the `build` and `volumes` section (if present) for the corresponding service (you only need to do this once).

Any golang service with a `volumes` block will automatically watch for changes made to `.go` and `.c` files, and will rebuild the service automatically when they occur.

If you need to make a change to a file that's not under watch, such as a JSON config file, or for golang services without a volume mount, you will need to rebuild the image against the code you've modified locally, with:
* `docker-compose build [service]`; then
* `docker-compose up -d [service]` (you **don't** have to run `docker-compose down` first)

`docker-compose` will detect that the container has changed, and recreate and restart only the changed container. If you specify the service via the optional `service` arg, only that service will be rebuilt.  Otherwise, all services will be scanned for changes, and will be rebuilt as required.

##### Node-based containers
To prepare your repository clone for development:
* In a terminal window, make sure that you're in the same directory as the `docker-compose.yml` file.
* Set the optional Environment Variable for the repository you're working on.
  * If you were working on `styx`, you would `export TP_STYX_DIR=<Full path to styx clone>`, for example `export TP_STYX_DIR=$PWD/styx`
* Edit the `docker-compose.yml`, and un-comment  the `volumes` section for the corresponding service (you only need to do this once).
* Build the node dependencies in your local repository clone by running:
  * `docker-compose run styx yarn install` (you only need to do this once)
* Run `docker-compose up -d` to trigger the changes to the Docker container

Every time you change Node code locally, the `npm start` running inside the container should notice the change and rebuild the code.
You can validate that this is working by running the following (from the same directory that the `docker-compose.yml` file is in):
* `docker-compose logs -f styx`

##### The `blip` container
The `blip` container has some extra features that the other Node-based containers do not have.

To run the container with `DEV_TOOLS` set to false:
* `DEV_TOOLS=false docker-compose up -d blip`

To go back to running the container with `DEV_TOOLS` set to true:
* `docker-compose up -d blip`

[To link `viz` in the `blip` container](https://github.com/tidepool-org/viz#running-locally-with-blip):
* In a terminal window, make sure that you're in the same directory as the `docker-compose.yml` file.
* Set the optional Environment Variable for both the `blip` and `viz` repositories:
  * For example, `export TP_BLIP_DIR=$PWD/blip` and `export TP_VIZ_DIR=$PWD/viz`
* Edit the `docker-compose.yml`, and un-comment the `/app` and `/viz` volumes from the `volumes` section for the `blip` service (you only need to do this once).
* Edit the `docker-compose.yml`, and un-comment the `viz` service definition (you only need to do this once). This will ensure that you always have a running `viz` service, which is required for the webpack builds in `blip`
* Link `viz` in your container by running the following (you only need to do this once):
  * `docker-compose up -d`
  * `docker-compose run blip /bin/sh -c "cd /viz && yarn link && cd /app && yarn link @tidepool/viz"`

To link `tideline` in the `blip` container:
* In a terminal window, make sure that you're in the same directory as the `docker-compose.yml` file.
* Set the optional Environment Variable for both the `blip` and `tideline` repositories:
  * For example, `export TP_BLIP_DIR=$PWD/blip` and `export TP_TIDELINE_DIR=$PWD/tideline`
* Edit the `docker-compose.yml`, and un-comment the `/app` and `/tideline` volumes from the `volumes` section for the `blip` service (you only need to do this once).
* Link `tideline` in your container by running the following (you only need to do this once):
  * `docker-compose up -d`
  * `docker-compose run blip /bin/sh -c "cd /tideline && yarn link && cd /app && yarn link tideline"`

### Using the `tidepool` helper script to manage the docker stack
Included at the root of this repo is a bash script named `tidepool`. It's intended to be a helpful cli tool to make some of the above management easier for developers who may not be very familiar with docker (and docker-compose) commands and concepts, or, who are familiar with them, but find them a bit verbose compared to working within their local OS.

This is especially useful in providing shortcuts for a few common development scenarios:
- link and unlink supporting packages in `blip`, such as `viz` and `tideline`
  - `tidepool link blip viz @tidepool/viz`
  - `tidepool link blip tideline`
  - `tidepool unlink blip viz`
- run npm (yarn) scripts in a service
  - `tidepool blip install`
  - `tidepool tideline run test-watch`
  - `tidepool viz run stories`

This script will only work in a Linux or MacOS environment (though Windows users may be able to get it working in [GitBash](https://git-for-windows.github.io/) or the new [Bash integration in Windows 10](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide))

While you can run the script in this directory via `./tidepool`, it's recommended that you copy it over to a location where it will be found in your `$PATH`, such as your `/usr/local/bin` directory.

In that case, you can run it from any location in your filesystem, which is very convenient.

Before using this tool, you need to set the TP_BASE_DIR environment variable to the location of your docker-compose.yml file for the tidepool stack.
i.e. `export TP_BASE_DIR="/Users/MY_USER/tidepool"`

After that, usage is as follows:
| Use command...                           | When you want to                                                                                                                                            |
|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tidepool up`                            | start and/or (re)build the tidepool stack                                                                                                                   |
| `tidepool down`                          | shut down the tidepool stack                                                                                                                                |
| `tidepool restart [service]`             | restart the entire tidepool stack or the specified service                                                                                                  |
| `tidepool pull [service]`                | pull the latest images for the entire tidepool stack or the specified service                                                                               |
| `tidepool logs [service]`                | tail logs for the entire tidepool stack or the specified service                                                                                            |
| `tidepool rebuild [service]`             | rebuild and run image for all services in the tidepool stack or the specified service                                                                       |
| `tidepool run service [...cmds]`         | run arbitrary shell commands against a service                                                                                                              |
| `tidepool link service dir`              | yarn link a mounted package and restart the service (package must be mounted into a root directory that matches it's name)                                  |
| `tidepool unlink service dir`            | yarn unlink a mounted package, reinstall the remote package, and restart the service (package must be mounted into a root directory that matches it's name) |
| `tidepool list`                          | list running services in the tidepool stack                                                                                                                 |
| `tidepool [node_service] [...cmds]`      | shortcut to run yarn commands against the specified service                                                                                                 |
| `tidepool help`                          | show more detailed usage text than what's listed here                                                                                                       |

## Development VM using Vagrant
Tidepool also has a VM for quickly firing up a development environment on your local machine.
The [Docker development environment](#docker-development-environment) is recommended for development, unless you're familiar with Vagrant and you prefer it over Docker.

The [Vagrant](https://www.vagrantup.com/) configuration creates a single VM and checks out all of the Tidepool git repositories.

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
