This script migrates user metadata from an old SALT_DEPLOY to a new SALT_DEPLOY
for Seagull. The Seagull process should be stopped and user access to the
environment prohibited.

Note: Backup the Mongo database before executing

In a terminal on the Mongo master node for the specified environment, execute the following commands:

```
# Set ENVIRONMENT (prod|staging|devel|test|local)
export ENVIRONMENT=prod

# Set seagull OLD_SALT_DEPLOY
$ read -s OLD_SALT_DEPLOY
<enter seagull old SALT_DEPLOY here>
$ export OLD_SALT_DEPLOY

# Set seagull NEW_SALT_DEPLOY (if empty will not apply encryption)
$ read -s NEW_SALT_DEPLOY
<enter seagull new SALT_DEPLOY here>
$ export NEW_SALT_DEPLOY

# Set MONGO_OPTIONS to host and port of mongo master connection
# If not specified, defaults to localhost
$ export MONGO_OPTIONS="--host localhost --port 27017"    # Use environment specific access points

# Stop Seagull (and presumably all user access)

# Migrate the metadata
$ ./migrate_metadata.sh ${ENVIRONMENT} 2> migrate_metadata.err | tee migrate_metadata.out

# Start Seagull with the new SALT_DEPLOY (and presumably all user access)
```
