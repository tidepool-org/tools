# General

Over time the names of the MongoDB databases and collections used during local development have drifted from those used in a deployment. For example, the database that contains all of the device data is named "streams" in local development while it is named "data" in a deployment.

The code in the following repositories was updated to resolve this discrepancy.

- http://github.com/tidepool-org/gatekeeper
- http://github.com/tidepool-org/hydrophone
- http://github.com/tidepool-org/jellyfish
- http://github.com/tidepool-org/message-api
- http://github.com/tidepool-org/octopus
- http://github.com/tidepool-org/platform
- http://github.com/tidepool-org/seagull
- http://github.com/tidepool-org/shoreline
- http://github.com/tidepool-org/tide-whisperer
- http://github.com/tidepool-org/tools

In order to use this updated code you will have to migrate the code and local database using the following instructions.

# Instructions

1. Shutdown all locally running Tidepool services (eg. `tp_kill`).
1. Update the code for all Tidepool services to the latest (eg. `get_current_tidepool_repos.sh`).
1. Start MongoDB (eg. `tp_mongo()` or `mongod` in a new terminal window).
1. Backup your database (eg. `mongodump --archive=backup.20160816`).
1. Execute the following to copy the old databases and collections to the new names:
```
mongo local --eval 'db.copyDatabase("gate", "gatekeeper");'
mongo local --eval 'db.copyDatabase("hydrophone", "confirm");'
mongo local --eval 'db.copyDatabase("streams", "data");'
mongo local --eval 'db.copyDatabase("user", "seagull");'
```
1. Start all Tidepool services (eg. `source tools/runservers`) and test.
1. Once you are sure the migration was successful, execute the following to cleanup the old databases and collections:
```
mongo gate --eval 'db.dropDatabase();'
mongo hydrophone --eval 'db.dropDatabase();'
mongo streams --eval 'db.dropDatabase();'
mongo seagull --eval 'db.oauth_access.drop(); db.tokens.drop(); db.users.drop();'
mongo user --eval 'db.seagull.drop();'
```