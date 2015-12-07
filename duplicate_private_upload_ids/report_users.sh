#!/bin/bash -eu

# Requires: mongo, base64, openssl, jq
# base64 - works on both ubuntu and macos

# Requirements:
#
# The following support tools are required:
#
# mongo - database; already required by Tidepool
# base64 - BASE64 encoding/decoding; common on most *nix distributions
# openssl - AES256 encryption/decryption; common on most *nix distributions
# jq - JSON parsing; use `brew install jq` to install on Mac
#
# The following environment variable is required:
#
# SALT_DEPLOY - export of the Seagull SALT_DEPLOY for the target environment
#
# To export this environment variable:
#
# $ read -s SALT_DEPLOY
# <copy-paste-the-seagull-salt-deploy-and-press-return>
# $ export SALT_DEPLOY
#
# Parameters:
#
# 1 - target environment; one of 'prd', 'stg', 'dev', 'test', 'local';
#     'test' environment is only for an AWS cluster without SSL-enabled mongo
# 2 - optional user_id; if supplied report only on the specified user; otherwise
#     report on all users
#
# Output:
#
# The output columns are:
#
# username | user_id | metadata_id | metadata_hash | private_uploads_id | private_uploads_hash | private_uploads_count | private_uploads_no_device_id_count | private_uploads_upload_ids | private_uploads_device_ids
#
# username - the username of the user
# user_id - the id of the user
# metadata_id - the id for the metadata associated with the user
# metadata_hash - the encryption hash for the metadata associated with the user
# private_uploads_id - the _groupId for all device data for the user
# private_uploads_hash - (currently unused)
# private_uploads_count - total count of all device data records for the user
# private_uploads_no_device_id_count - total count of all device data records for the user that do not have a deviceId property
# private_uploads_upload_ids - JSON array; all uploadIds for all device data for the user
# private_uploads_device_ids - JSON array; all deviceIds for all device data for the user

if [ -z "$(which mongo)" -o -z "$(which base64)" -o -z "$(which openssl)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, base64, openssl, jq" >&2
  exit 1
fi

# SALT_DEPLOY environment variable must be exported outside of this script
if [ -z "${SALT_DEPLOY:-}" ]; then
  echo "ERROR: Required environment variables: SALT_DEPLOY" >&2
  exit 1
fi

# Environment
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be environment: prd, stg, dev, test, local" >&2
  exit 1
else
  environment="${1}"
fi
case "${environment}" in
  prd|stg|dev)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --ssl --sslAllowInvalidCertificates --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="seagull"
    DEVICEDATA_DATABASE="data"
    ;;
  test)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="seagull"
    DEVICEDATA_DATABASE="data"
    ;;
  local)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="user"
    DEVICEDATA_DATABASE="streams"
    ;;
  *)
    echo "ERROR: First argument must be environment: prd, stg, dev, test, local" >&2
    exit 1
esac

# User(s)
if [ -z "${2:-}" ]; then
  USER_CLAUSE=
else
  USER_CLAUSE="{userid: \"${2}\"}"
fi

report_user()
{
  unset username
  unset user_id
  unset metadata_id
  unset metadata_hash
  unset metadata_encrypted
  unset secret_key
  unset metadata_decrypted
  unset private_uploads_id
  unset private_uploads_hash
  unset private_uploads_count
  unset private_uploads_no_device_id_count
  unset private_uploads_device_ids

  echo "PROCESSING: ${1}" >&2

  IFS=\| read username user_id metadata_id metadata_hash <<< "${1}"
  if [ ${#username} -lt 1 -o ${#user_id} -ne 10 -o ${#metadata_id} -ne 10 -o ${#metadata_hash} -ne 24 ]; then
    echo "WARN: Ignoring non-standard user information: ${user}" >&2
    return
  fi

  metadata_encrypted="$(mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "db.seagull.find({_id: \"${metadata_id}\"}).forEach(function(f) { print(f.value); })")"
  if [ ${#metadata_encrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing encrypted metadata for user: ${user}" >&2
    return
  fi

  secret_key="$(printf "${metadata_hash}${SALT_DEPLOY}" | openssl dgst -sha256 -hex | sed 's/.* //')"

  metadata_decrypted="$(printf "${metadata_encrypted}" | base64 --decode | openssl enc -d -aes256 -k "${secret_key}" | sed 's/\\"/\\\\"/g')"
  if [ ${#metadata_decrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing decrypted metadata for user: ${user}" >&2
    return
  fi

  read private_uploads_id private_uploads_hash <<< $(printf "${metadata_decrypted}" | jq -r ".private.uploads.id, .private.uploads.hash")

  private_uploads_count="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "db.deviceData.find({\$or: [{_groupId: \"${private_uploads_id}\"}, {groupId: \"${private_uploads_id}\"}]}).count()")"

  if [ ${private_uploads_count} -gt 0 ]; then
    private_uploads_no_device_id_count="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "db.deviceData.find({\$or: [{_groupId: \"${private_uploads_id}\"}, {groupId: \"${private_uploads_id}\"}], deviceId: {\$exists: false}}).count()")"
    private_uploads_upload_ids="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "printjson(db.deviceData.distinct(\"uploadId\", {\$or: [{_groupId: \"${private_uploads_id}\"}, {groupId: \"${private_uploads_id}\"}]}))" | jq -s -c .[0])"
    private_uploads_device_ids="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "printjson(db.deviceData.distinct(\"deviceId\", {\$or: [{_groupId: \"${private_uploads_id}\"}, {groupId: \"${private_uploads_id}\"}]}))" | jq -s -c .[0])"
  else
    private_uploads_no_device_id_count=0
    private_uploads_upload_ids=
    private_uploads_device_ids=
  fi

  echo "${username}|${user_id}|${metadata_id}|${metadata_hash}|${private_uploads_id}|${private_uploads_hash}|${private_uploads_count}|${private_uploads_no_device_id_count}|${private_uploads_upload_ids}|${private_uploads_device_ids}"
}

report_users()
{
  users="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find(${USER_CLAUSE}).forEach(function(f) { print(f.username + '|' + f.userid + '|' + (f.private && f.private.meta ? f.private.meta.id : '') + '|' + (f.private && f.private.meta ? f.private.meta.hash : '')); })")"
  if [ ${#users} -gt 0 ]; then
    echo "${users}" | while read -r user; do
      report_user "${user}"
      sleep 0.05
    done
  fi
}

report_users
