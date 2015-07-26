#!/bin/bash -eu

# Requires: mongo, base64, openssl, jq
# base64 - works on both ubuntu and macos

if [ -z "$(which mongo)" -o -z "$(which base64)" -o -z "$(which openssl)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, base64, openssl, jq" >&2
  exit 1
fi

# SALT_DEPLOY, SERVER_SECRET, SHORELINE_API, SEAGULL_API environment variables must be exported outside of this script
if [ -z "${SALT_DEPLOY:-}" -o -z "${SERVER_SECRET:-}" -o -z "${SHORELINE_API:-}" -o -z "${SEAGULL_API:-}" ]; then
  echo "ERROR: Required environment variables: SALT_DEPLOY, SERVER_SECRET, SHORELINE_API, SEAGULL_API" >&2
  exit 1
fi

# Environment
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be environment: production, staging, development, test, local" >&2
  exit 1
else
  environment="${1}"
fi
case "${environment}" in
  production|staging|development)
    MONGO_OPTIONS="-ssl --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="seagull"
    DEVICEDATA_DATABASE="data"
    ;;
  test)
    MONGO_OPTIONS="--quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="seagull"
    DEVICEDATA_DATABASE="data"
    ;;
  local)
    MONGO_OPTIONS="--quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="user"
    DEVICEDATA_DATABASE="streams"
    ;;
  *)
    echo "ERROR: First argument must be environment: production, staging, development, test, local" >&2
    exit 1
esac

shift

reset_user_private_uploads()
{
  unset username
  unset user_id
  unset metadata_id
  unset metadata_hash
  unset session_token
  unset secret_key
  unset metadata_encrypted
  unset metadata_decrypted
  unset metadata_decrypted_private_uploads
  unset updated_metadata_decrypted
  unset updated_metadata_encrypted

  IFS=\| read username user_id metadata_id metadata_hash <<< "${1}"
  if [ ${#username} -lt 1 -o ${#user_id} -ne 10 -o ${#metadata_id} -ne 10 -o ${#metadata_hash} -ne 24 ]; then
    echo "WARN: Ignoring non-standard user information: ${user}" >&2
    return
  fi

  session_token=$(curl -s -v -H "x-tidepool-server-name: ${user_id}" -H "x-tidepool-server-secret: ${SERVER_SECRET}" -X POST "${SHORELINE_API}/serverlogin" 2>&1 | grep "X-Tidepool-Session-Token" | cut -d' ' -f3)
  if [ ${#session_token} -lt 1 ]; then
    echo "ERROR: Failure to obtain session token for user: ${user}" >&2
    return
  fi

  secret_key="$(printf "${metadata_hash}${SALT_DEPLOY}" | openssl dgst -sha256 -hex | sed 's/.* //')"
  if [ ${#secret_key} -lt 1 ]; then
    echo "ERROR: Failure to calculate secret key for user: ${user}" >&2
    return
  fi

  metadata_encrypted="$(mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "db.seagull.find({_id: \"${metadata_id}\"}).forEach(function(f) { print(f.value); })")"
  if [ ${#metadata_encrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing encrypted metadata for user: ${user}" >&2
    return
  fi

  metadata_decrypted="$(printf "${metadata_encrypted}" | base64 --decode | openssl enc -d -aes256 -k "${secret_key}")" # | sed 's/\\"/\\\\"/g')"
  if [ ${#metadata_decrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing decrypted metadata for user: ${user}" >&2
    return
  fi
  metadata_decrypted_private_uploads="$(printf "${metadata_decrypted}" | jq -r -c ".private.uploads")"

  updated_metadata_decrypted="$(printf "${metadata_decrypted}" | jq -r -c "del(.private.uploads)")"
  if [ ${#updated_metadata_decrypted} -lt 1 ]; then
    echo "ERROR: Invalid decrypted updated metadata for user: ${user}" >&2
    return
  fi

  updated_metadata_encrypted="$(printf "${updated_metadata_decrypted}" | openssl enc -e -aes256 -k "${secret_key}" | base64)"
  if [ ${#updated_metadata_encrypted} -lt 1 ]; then
    echo "ERROR: Invalid encrypted updated metadata for user: ${user}" >&2
    return
  fi

  mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "db.seagull.update({_id: \"${metadata_id}\"}, {_id: \"${metadata_id}\", value: \"${updated_metadata_encrypted}\"})"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failure to update mongo for user: ${user}" >&2
    return
  fi

  echo "${username} ${user_id} ${metadata_decrypted_private_uploads}"
}

reset_users_private_uploads()
{
  echo "PROCESSING: ${1}" >&2

  users="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find({userid: \"${1}\"}).forEach(function(f) { print(f.username + '|' + f.userid + '|' + f.private.meta.id + '|' + f.private.meta.hash); })")"
  if [ ${#users} -lt 1 ]; then
    echo "WARN: Unable to find user with id: ${1}" >&2
    sleep 0.05
  else
    for user in ${users}; do
      reset_user_private_uploads "${user}"
      sleep 0.05
    done
  fi
}

# Loop through arguments (if any) or stdin
if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    reset_users_private_uploads "${1}"
    shift
  done
else
  while read line; do
    reset_users_private_uploads "${line}"
  done
fi
