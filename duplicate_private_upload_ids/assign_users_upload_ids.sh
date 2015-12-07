#!/bin/bash -eu

# Requires: mongo

if [ -z "$(which mongo)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, jq" >&2
  exit 1
fi

# SERVER_SECRET, SHORELINE_API, SEAGULL_API environment variables must be exported outside of this script
if [ -z "${SERVER_SECRET:-}" -o -z "${SHORELINE_API:-}" -o -z "${SEAGULL_API:-}" ]; then
  echo "ERROR: Required environment variables: SALT_DEPLOY, SERVER_SECRET, SHORELINE_API, SEAGULL_API" >&2
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
    DEVICEDATA_DATABASE="data"
    ;;
  test)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    DEVICEDATA_DATABASE="data"
    ;;
  local)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    DEVICEDATA_DATABASE="streams"
    ;;
  *)
    echo "ERROR: First argument must be environment: prd, stg, dev, test, local" >&2
    exit 1
esac

# User id
if [ -z "${2:-}" ]; then
  echo "ERROR: Second argument must be user_id" >&2
  exit 1
else
  user_id="${2}"
fi

# Upload id
if [ -z "${3:-}" ]; then
  echo "ERROR: Third argument must be upload_id" >&2
  exit 1
else
  upload_id="${3}"
fi

assign_users_upload_ids()
{
  unset user_id
  unset upload_id
  unset session_token
  unset private_uploads
  unset private_uploads_id

  user_id="${1}"
  upload_id="${2}"

  session_token=$(curl -s -v -k -H "x-tidepool-server-name: ${user_id}" -H "x-tidepool-server-secret: ${SERVER_SECRET}" -X POST "${SHORELINE_API}/serverlogin" 2>&1 | grep "X-Tidepool-Session-Token" | cut -d' ' -f3)
  if [ ${#session_token} -lt 1 ]; then
    echo "ERROR: Failure to obtain session token for user_id: ${user_id}" >&2
    return
  fi

  private_uploads="$(curl -s -k -H "x-tidepool-session-token: ${session_token}" -X GET "${SEAGULL_API}/${user_id}/private/uploads")"
  if [ ${#private_uploads} -lt 1 ]; then
    echo "ERROR: Private uploads not found for user_id: ${user_id}" >&2
    return
  fi

  private_uploads_id="$(printf "${private_uploads}" | jq -r ".id")"
  if [ ${#private_uploads_id} -lt 1 ]; then
    echo "ERROR: Private uploads id not found for user_id: ${user_id}" >&2
    return
  fi

  echo "INFO: Assigning upload id '${upload_id}' to user id '${user_id}' with private uploads id '${private_uploads_id}'"
  mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "db.deviceData.update({uploadId: \"${upload_id}\"}, {\$set: {_groupId: \"${private_uploads_id}\"}}, {multi: true})"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failure to update mongo for upload_id: ${upload_id}" >&2
    return
  fi
}

assign_users_upload_ids "${user_id}" "${upload_id}"
