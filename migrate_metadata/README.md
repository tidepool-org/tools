### Description

This script migrates encrypted user metadata in the Seagull database from an old SALT_DEPLOY to a new SALT_DEPLOY. The Seagull process should be stopped and user access to the environment prohibited.

Note: Backup the Mongo database before executing.

### General Instructions

In a terminal on the Mongo master node for the specified environment, execute the following commands:

```
# Set ENVIRONMENT (prd|stg|dev|test|local)
export ENVIRONMENT=prd

# Set seagull OLD_SALT_DEPLOY
read -s OLD_SALT_DEPLOY
<enter seagull old SALT_DEPLOY here>
export OLD_SALT_DEPLOY

# Set seagull NEW_SALT_DEPLOY (if empty will not apply encryption)
read -s NEW_SALT_DEPLOY
<enter seagull new SALT_DEPLOY here>
export NEW_SALT_DEPLOY

# Set MONGO_OPTIONS to host and port of mongo master connection
# If not specified, defaults to localhost
export MONGO_OPTIONS="--host localhost --port 27017"    # Use environment specific access points

# Stop Seagull (and presumably all user access)

# Migrate the metadata
./migrate_metadata.sh ${ENVIRONMENT} 2> migrate_metadata.err | tee migrate_metadata.out

# Start Seagull with the new SALT_DEPLOY (and presumably all user access)
```

### [Seagull v0.1.22](https://github.com/tidepool-org/seagull/releases/tag/v0.1.22) Upgrade

To remove all metadata encryption in the Seagull database in your local environment prior to upgrading to [Seagull v0.1.22](https://github.com/tidepool-org/seagull/releases/tag/v0.1.22), from the command line:

```
export OLD_SALT_DEPLOY="KEWRWBe5yyMnW4SxosfZ2EkbZHkyqJ5f"   # From ../runservers
./migrate_metadata.sh local 2> migrate_metadata.err | tee migrate_metadata.out
```
