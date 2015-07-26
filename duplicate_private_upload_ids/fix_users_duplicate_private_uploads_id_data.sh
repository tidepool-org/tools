#!/bin/bash -eu

# Requires: mongo, jq

if [ -z "$(which mongo)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, jq" >&2
  exit 1
fi

# Environment
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be environment: production, staging, development, local" >&2
  exit 1
else
  environment="${1}"
fi
case "${environment}" in
  production|staging|development)
    MONGO_OPTIONS="-ssl --quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="data"
    ;;
  local)
    MONGO_OPTIONS="--quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="streams"
    ;;
  *)
    echo "ERROR: First argument must be environment: production, staging, development, local" >&2
    exit 1
esac

# Report path
if [ -z "${2:-}" ]; then
  echo "ERROR: Second argument must be the output file from report_users.sh" >&2
  exit 1
else
  report_path="${2}"
fi

directory="$(dirname ${0})"

reset_users_private_uploads()
{
  unset username
  unset user_id

  IFS=\| read username user_id <<< "${1}"
  echo "${directory}/reset_users_private_uploads.sh ${environment} ${user_id} # ${username}"
}

assign_users_upload_ids()
{
  unset upload_id
  unset user_id
  unset assign_user_id
  unset username
  unset assign_username

  upload_id="${1}"

  user_id="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "db.deviceData.find({type: \"upload\", uploadId: \"${upload_id}\"}).forEach(function(f) { print(f.byUser); })")"
  if [ ${#user_id} -lt 1 ]; then
    echo "WARN: Ignoring upload id without upload type data or without user id: ${upload_id}" >&2
    return
  fi

  username="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find({userid: \"${user_id}\"}).forEach(function(f) { print(f.username); })")"
  if [ ${#username} -lt 1 ]; then
    echo "WARN: Ignoring upload id where upload user id does not contain username: ${upload_id} ${user_id}" >&2
    return
  elif [[ "${username}" =~ .*-home@replacebg\.org ]]; then
    assign_username="$(printf "${username}" | sed 's/\(.*\)-home\(@replacebg\.org\)/\1\2/')"
    assign_user_id="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find({username: \"${assign_username}\"}).forEach(function(f) { print(f.userid); })")"
    if [ ${#user_id} -lt 1 ]; then
      echo "WARN: Ignoring upload id where upload username does not contain user id: ${upload_id} ${assign_username}" >&2
      return
    fi
  elif [[ "${username}" =~ .*@replacebg\.org ]]; then
    assign_username="${username}"
    assign_user_id="${user_id}"
  else
    echo "ERROR: Ignoring upload id where username not in ReplaceBG study: ${upload_id} ${user_id} ${username}" >&2
    return
  fi

  if [ "${assign_user_id}" != "${user_id}" ]; then
    echo "${directory}/assign_users_upload_ids.sh ${environment} ${assign_user_id} ${upload_id} # ${assign_username} <= ${username}"
  else
    echo "${directory}/assign_users_upload_ids.sh ${environment} ${assign_user_id} ${upload_id} # ${assign_username}"
  fi
}

fix_users_duplicate_private_uploads_id_data()
{
  duplicate_users="$("${directory}/report_users_duplicate_private_uploads_id_data.sh" "${report_path}" | cut -d'|' -f1,2)"
  for duplicate_user in ${duplicate_users}; do
    reset_users_private_uploads "${duplicate_user}"
  done

  upload_ids="$("${directory}/report_users_duplicate_private_uploads_id_data.sh" "${report_path}" | cut -d'|' -f9 | jq -r '.[]' | sort | uniq)"
  for upload_id in ${upload_ids}; do
    assign_users_upload_ids "${upload_id}"
  done
}

fix_users_duplicate_private_uploads_id_data
