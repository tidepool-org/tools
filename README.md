tools
=====

A place to put tooling and scripts that help when working on Tidepool stuff.

Contains:

## `addLicense.py`
addLicense.py is a script to add license text to a set of source files by
searching for special markers in those files.  It's reasonably smart.  Run it
with the `-h` switch for full help.

## `extractDocs.py`
`extractDocs.py` is designed to allow a natural form of documentation to be
placed in source files that can then be extracted and formatted appropriately
for markdown files like the apiary documentation and also function-oriented
docs like you'll find in the `*-client` libraries.

It's driven by regular expressions and python's native formatting, which means
the configuration file is a little cryptic. But it was fast to implement and
does the job of making it so that it's easier to keep code and docs in sync.

Once it's set up in a given repository, one merely has to run this to update
the docs.

## `runservers`
This is a bash shell script to run a set of servers on localhost. We'll keep
updating it as we grow.

```bash
```
# Usage

```bash
$ npm install # this installs all packages from their respective
# master branch
# to clone all repos locally
$ export PATH="$PATH:./node_modules/.bin:./bin"
$ clone-all.sh
# from now one, we assume you have performed npm install by yourself
$ link-all.sh # npm link all services from sibling directories
$ start.sh # run the whole platform locally
```

Using `start.sh` is the recommended way to control all the Tidepool
daemons from one terminal.

## `git-npm-sibling-link`

Use local sibling directory as linked npm module.
This allows using a sibling directory as an npm dependency.
If the directory is not actually a sibling directory, you can provide the full
path as the second argument.

```bash
$ ./git-npm-sibling-link
usage ./git-npm-sibling-link <package> [/full/non/sibling/path]
```
```bash
$ pwd
/home/bewest/src/tidepool/node-tidepool-servers
$ git-npm-sibling-link user-api
setting up npm to use user-api from ../user-api
/home/bewest/src/tidepool/user-api
{ http_parser: '1.0',
  node: '0.10.24',
  v8: '3.14.5.9',
  ares: '1.9.0-DEV',
  uv: '0.10.21',
  zlib: '1.2.3',
  modules: '11',
  openssl: '1.0.1e',
  npm: '1.3.21',
  'user-api': '0.0.6' }
/usr/local/lib/node_modules/user-api -> /home/bewest/src/tidepool/user-api
/home/bewest/src/tidepool/node-tidepool-servers
unbuild user-api@0.0.6
/home/bewest/src/tidepool/node-tidepool-servers/node_modules/user-api -> /usr/local/lib/node_modules/user-api -> /home/bewest/src/tidepool/user-api
```

## `git-tidepool-repo-url`
Print `git://` url suitable for npm install.
```bash
$ ./git-tidepool-repo-url hakken
git://github.com/tidepool-org/hakken.git#master
# useful for eg
$ npm install --save $(./git-tidepool-repo-url hakken)
```

## `bin/`
Sundry tools to install, link, and start tidepool daemons.


#### Per service daemon

Each service has it's own script to start itself.
Each script is provided so that things can be customized per daemon, if
necessary; the basic idea is to establish some environment variables and then
start node using a designated entry point.

An especially handy way to establish environment variables is to put
`KEY=VALUE` pairs separated in a file.  This is a valid shell script, and
automatically read by tools such as foreman.

Here are two convenient ways to set a process' environment variables if they
are in such a file:

```bash
$ env $(cat my.env) my-proc # setup environment for my-proc using variables my.env
$ . <(my.env) # source from redirected stdin from file
```

See [node-foreman](https://github.com/strongloop/node-foreman)
for further reference.  A list of processes is kept in `Procfile`.
Additionally, `node` is replaced with `nodemon` which restarts the daemon if
your source files change.
Some authors may also take advantage of the fact that `.env` files
processed by `node-foreman` can be `json` as well.

~bewest uses these tools from the root of this git repo, and adds
`./bin/` to the `PATH`:
```bash
$ export PATH="$PATH:./node_modules/.bin:./bin"
```
These tools assume you want to control things from the root for this
directory.  The tools help configure sibling directories.

In order to locally preview sources you want to work on you must first
`npm link` the dependency in the dependency's root directory, then 

### `bin/start.sh`

This is the push button development script.  It runs `node-foreman` to
enslave each daemon according to it's per daemon configuration.

`start.sh`

This takes over the terminal and colorizes output from all the
daemons.  `CTRL-C` will kill all the daemons, allowing you to restart
all or some of them consistently.

Simple wrapper around `foreman` to include `etc/common.env` as the default
environment.

### `bin/sandcastle.sh`
Start sandcastle daemon.

### `bin/message-api.sh`
Start message-api daemon.
### `bin/hakken.sh`
Start hakken coordinator.
### `bin/seagull.sh`
Start seagull daemon.
### `bin/styx.sh`
Start styx router.
### `bin/armada.sh`
Start armada api.
### `bin/pool-whisperer.sh`
Start the pool-whisperer.
### `bin/jellyfish.sh`
Start jellyfish.
### `bin/user-api.sh`
Start user-api.
### `bin/blip.sh`
Start blip in development mode.

### `bin/link-all.sh`
Set up npm to symlink all the necessary sibling directories in one go.
### `bin/tidepool-services-ls.sh`
List all the services needed to run tidepool (blip).
### `bin/clone-all.sh`
Clone all repos needed to run blip.
### `bin/clone-sibling.sh`
Clone a repo in a sibling directory.

### `bin/common`
Some shared scripts.
Mainly a function to load environment files into environment
variables (via another shell variable due to shell quoting quirks).

Sourced by every script.


