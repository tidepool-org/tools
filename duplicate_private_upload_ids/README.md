These scripts report and fix duplicate private uploads ids.  

Note: Backup the Mongo database before executing these

In a terminal on the mongo master node for the specified environment, execute the following commands:

```
# Set ENVIRONMENT (production|staging|development|test|local)
export ENVIRONMENT=production

# Set environment SERVER_SECRET
$ read -s SERVER_SECRET
<enter environment SERVER_SECRET here>
$ export SERVER_SECRET

# Set seagull SALT_DEPLOY
$ read -s SALT_DEPLOY
<enter seagull SALT_DEPLOY here>
$ export SALT_DEPLOY

# Set SHORELINE_API and SEAGULL_API
$ export SEAGULL_API="http://localhost:9120"		  # Use environment specific access points
$ export SHORELINE_API="http://localhost:9107"		# Use environment specific access points

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
```
