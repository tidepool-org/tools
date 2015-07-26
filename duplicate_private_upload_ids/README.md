These scripts report and fix duplicate private uploads ids.  

Note: Backup the Mongo database before executing these

In a terminal on the mongo master node for the specified environment, execute the following commands:

```
# Set ENVIRONMENT (prod|staging|devel|test|local)
export ENVIRONMENT=prod

# Set environment SERVER_SECRET
$ read -s SERVER_SECRET
<enter environment SERVER_SECRET here>
$ export SERVER_SECRET

# Set seagull SALT_DEPLOY
$ read -s SALT_DEPLOY
<enter seagull SALT_DEPLOY here>
$ export SALT_DEPLOY

# Set MONGO_OPTIONS to host and port of mongo master connection
# If not specified, defaults to localhost
$ export MONGO_OPTIONS="--host localhost --port 27017"    # Use environment specific access points

# Set SHORELINE_API and SEAGULL_API
$ export SHORELINE_API="http://localhost:9107"		        # Use environment specific access points
$ export SEAGULL_API="http://localhost:9120"		          # Use environment specific access points

# Dump all useful user information to file for later use
$ ./report_users.sh ${ENVIRONMENT} 2> users.err | tee users.out

# Determine all commands needed to fix accounts WITHOUT data
$ ./fix_users_duplicate_private_uploads_id_empty.sh ${ENVIRONMENT} users.out
... outputs a list of commands you can review and then run (in order) to fix accounts

# Determine all commands needed to fix accounts WITH data
$ ./fix_users_duplicate_private_uploads_id_data.sh ${ENVIRONMENT} users.out
... outputs a list of commands you can review and then run (in order) to fix accounts

# After running all fix commands, re-dump all useful user information and
# look for any remaining duplicates (there should be none)
$ ./report_users.sh ${ENVIRONMENT} 2> users.fixed.err | tee users.fixed.out
$ ./report_users_duplicate_private_uploads_id_empty.sh users.fixed.out
$ ./report_users_duplicate_private_uploads_id_data.sh users.fixed.out

# Simple sanity check
$ cat users.fixed.out | cut -d'|' -f5 | sort | uniq -d | grep -v '^null$'

# Other sanity checks (there should be no orphaned metadata or device data)
$ ./report_orphaned_metadata.sh ${ENVIRONMENT} users.fixed.out
$ ./report_orphaned_device_data.sh ${ENVIRONMENT} users.fixed.out
```
