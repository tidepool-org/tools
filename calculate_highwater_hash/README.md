This script simply converts a Tidepool platform user id to a Highwater hashed
user id used by Kissmetrics and AWS Dynamo DB. This script requires the Highwater
SALT_DEPLOY for the specified environment.

In a terminal on the Mongo master node for the specified environment, execute
the following commands:

```
# Set Highwater SALT_DEPLOY
$ read -s SALT_DEPLOY
<Enter Highwater SALT_DEPLOY>
$ export SALT_DEPLOY

$ echo "<user_id>" | ./calculate_highwater_hash
```

A common use case is to generate a list of ids to be excluded from metrics
calculations for accounts that are a) created by Tidepool employees for testing,
and b) used by the JAEB Replace BG study.

In a terminal on the Mongo master node for the specified environment, execute
the follow commands to generate a list of ids to be excluded from metrics:

```
# Set Highwater SALT_DEPLOY
$ read -s SALT_DEPLOY
<Enter Highwater SALT_DEPLOY>
$ export SALT_DEPLOY

# List of Highwater hashes from Tidepool test accounts
$ mongo user --ssl --sslAllowInvalidCertificates --quiet --eval "db.users.find({username: /^([^@]+|.+@(tidepool\.(org|io)|dufflite\.com))\$/}).forEach(function(f) { print(f.userid); });" | ./calculate_highwater_hash | sort > tidepool_highwater_hashes.txt

# List of Highwater hashes from ReplaceBG study accounts
$ mongo user --ssl --sslAllowInvalidCertificates --quiet --eval "db.users.find({username: /^.+@replacebg.org\$/}).forEach(function(f) { print(f.userid); });" | ./calculate_highwater_hash | sort > replacebg_highwater_hashes.txt
```
