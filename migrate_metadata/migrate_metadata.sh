#!/bin/bash -eu

# Requires: mongo, base64, openssl
# base64 - works on both ubuntu and macos

if [ -z "$(which mongo)" -o -z "$(which base64)" -o -z "$(which openssl)" ]; then
  echo "ERROR: Required tools: mongo, base64, openssl" >&2
  exit 1
fi

if [ -z "$(base64 --help | grep '\-\-wrap=')" ]; then
  BASE64_OPTIONS=
else
  BASE64_OPTIONS="--wrap=0"
fi

# OLD_SALT_DEPLOY environment variable must be exported outside of this script
if [ -z "${OLD_SALT_DEPLOY:-}" ]; then
  echo "ERROR: Required environment variable: OLD_SALT_DEPLOY" >&2
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
    ;;
  test)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="seagull"
    ;;
  local)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    SEAGULL_DATABASE="user"
    ;;
  *)
    echo "ERROR: First argument must be environment: prd, stg, dev, test, local" >&2
    exit 1
esac

shift

migrate_user_metadata()
{
  unset username
  unset user_id
  unset metadata_id
  unset metadata_hash
  unset old_secret_key
  unset new_secret_key
  unset metadata_encrypted
  unset metadata_decrypted

  IFS=\| read username user_id metadata_id metadata_hash <<< "${1}"
  if [ ${#username} -lt 1 -o ${#user_id} -ne 10 -o ${#metadata_id} -ne 10 -o ${#metadata_hash} -ne 24 ]; then
    echo "WARN: Ignoring non-standard user information: ${user}" >&2
    return
  fi

  old_secret_key="$(printf "${metadata_hash}${OLD_SALT_DEPLOY}" | openssl dgst -sha256 -hex | sed 's/.* //')"
  if [ ${#old_secret_key} -lt 1 ]; then
    echo "ERROR: Failure to calculate old secret key for user: ${user}" >&2
    return
  fi

  if [ -n "${NEW_SALT_DEPLOY:-}" ]; then
    new_secret_key="$(printf "${metadata_hash}${NEW_SALT_DEPLOY}" | openssl dgst -sha256 -hex | sed 's/.* //')"
    if [ ${#new_secret_key} -lt 1 ]; then
      echo "ERROR: Failure to calculate new secret key for user: ${user}" >&2
      return
    fi
  fi

  metadata_encrypted="$(mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "db.seagull.find({_id: \"${metadata_id}\"}).forEach(function(f) { print(f.value); })")"
  if [ ${#metadata_encrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing encrypted metadata for user: ${user}" >&2
    return
  fi

  metadata_decrypted="$(printf "${metadata_encrypted}" | base64 --decode | openssl enc -d -aes256 -k "${old_secret_key}")" # | sed 's/\\"/\\\\"/g')"
  if [ ${#metadata_decrypted} -lt 1 ]; then
    echo "WARN: Ignoring missing decrypted metadata for user: ${user}" >&2
    return
  fi

  if [ -n "${new_secret_key:-}" ]; then
    metadata_encrypted="$(printf "${metadata_decrypted}" | openssl enc -e -aes256 -k "${new_secret_key}" | base64 ${BASE64_OPTIONS})"
    if [ ${#metadata_encrypted} -lt 1 ]; then
      echo "ERROR: Invalid encrypted updated metadata for user: ${user}" >&2
      return
    fi
  else
    metadata_encrypted="${metadata_decrypted//\\/\\\\}"
    metadata_encrypted="${metadata_encrypted//\"/\\\"}"
  fi

  mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "db.seagull.update({_id: \"${metadata_id}\"}, {_id: \"${metadata_id}\", value: \"${metadata_encrypted}\"})"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failure to update mongo for user: ${user}" >&2
    return
  fi

  echo "${username} ${user_id}"
}

migrate_metadata()
{
  echo "PROCESSING USER METADATA" >&2

  users="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find().forEach(function(f) { print(f.username + '|' + f.userid + '|' + (f.private && f.private.meta ? f.private.meta.id : '') + '|' + (f.private && f.private.meta ? f.private.meta.hash : '')); })")"
  echo "${users}" | while read -r user; do
    migrate_user_metadata "${user}"
    sleep 0.05
  done
}

migrate_metadata
