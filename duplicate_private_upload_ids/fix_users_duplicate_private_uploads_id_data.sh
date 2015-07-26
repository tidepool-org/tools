#!/bin/bash -eu

# Requires: mongo, jq

if [ -z "$(which mongo)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, jq" >&2
  exit 1
fi

# Environment
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be environment: prod, staging, devel, test, local" >&2
  exit 1
else
  environment="${1}"
fi
case "${environment}" in
  prod)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} -ssl --quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="data"
    ;;
  staging)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} -ssl --quiet"
    USERS_DATABASE="user_staging"
    DEVICEDATA_DATABASE="data_staging"
    ;;
  devel)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} -ssl --quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="data"
    ;;
  test)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="data"
    ;;
  local)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    USERS_DATABASE="user"
    DEVICEDATA_DATABASE="streams"
    ;;
  *)
    echo "ERROR: First argument must be environment: prod, staging, devel, test, local" >&2
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
  unset upload
  unset private_uploads_id
  unset primary_user_id
  unset primary_username
  unset primary_private_uploads_id
  unset alternate_username
  unset alternate_user_id
  unset alternate_private_uploads_id

  upload_id="${1}"

  upload="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "db.deviceData.find({type: \"upload\", uploadId: \"${upload_id}\"}).forEach(function(f) { print((f._groupId ? f._groupId : f.groupId) + '|' + f.byUser); })")"
  if [ ${#upload} -lt 1 ]; then
    echo "WARN: Ignoring upload id without upload type data: ${upload_id}" >&2
    return
  fi

  IFS=\| read private_uploads_id primary_user_id <<< "${upload}"
  if [ ${#private_uploads_id} -lt 1 ]; then
    echo "WARN: Ignoring upload id without upload private uploads id: ${upload_id}" >&2
    return
  fi
  if [ ${#primary_user_id} -lt 1 ]; then
    echo "WARN: Ignoring upload id without upload user id: ${upload_id}" >&2
    return
  fi

  primary_username="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find({userid: \"${primary_user_id}\"}).forEach(function(f) { print(f.username); })")"
  if [ ${#primary_username} -lt 1 ]; then
    echo "WARN: Ignoring upload id where upload user id does not contain username: ${upload_id} ${primary_user_id}" >&2
    return
  fi
  primary_private_uploads_id="$(grep "^${primary_username}|${primary_user_id}|" "${report_path}" | cut -d'|' -f5)"

  if [[ "${primary_username}" =~ .*-home@replacebg\.org ]]; then
    alternate_username="$(printf "${primary_username}" | sed 's/\(.*\)-home\(@replacebg\.org\)/\1\2/')"
  elif [[ "${primary_username}" =~ .*@replacebg\.org ]]; then
    alternate_username="$(printf "${primary_username}" | sed 's/\(.*\)\(@replacebg\.org\)/\1-home\2/')"
  fi

  if [ -z "${alternate_username:-}" ]; then
    if [ "${primary_private_uploads_id}" != "${private_uploads_id}" ]; then
      echo "ERROR: Ignoring upload id where upload private uploads id does not match user private uploads id: ${upload_id} ${user_id}"
    else
      echo "${directory}/assign_users_upload_ids.sh ${environment} ${primary_user_id} ${upload_id} # ${primary_username}"
    fi
  else
    alternate_user_id="$(mongo ${MONGO_OPTIONS} ${USERS_DATABASE} --eval "db.users.find({username: \"${alternate_username}\"}).forEach(function(f) { print(f.userid); })")"
    if [ ${#alternate_user_id} -lt 1 ]; then
      echo "WARN: Ignoring upload id where upload username does not contain user id: ${upload_id} ${alternate_username}" >&2
      return
    fi
    alternate_private_uploads_id="$(grep "^${alternate_username}|${alternate_user_id}|" "${report_path}" | cut -d'|' -f5)"

    if [ "${primary_private_uploads_id}" == "${private_uploads_id}" -a "${alternate_private_uploads_id}" == "${private_uploads_id}" ]; then
      echo "ERROR: Ignoring upload id where more than one account could be associated with private uploads id: ${upload_id} ${primary_username} ${alternate_username}"
    elif [ "${primary_private_uploads_id}" == "${private_uploads_id}" ]; then
      echo "${directory}/assign_users_upload_ids.sh ${environment} ${primary_user_id} ${upload_id} # ${primary_username}"
    elif [ "${alternate_private_uploads_id}" == "${private_uploads_id}" ]; then
      echo "${directory}/assign_users_upload_ids.sh ${environment} ${alternate_user_id} ${upload_id} # ${alternate_username} <= ${primary_username}"
    else
      echo "ERROR: Ignoring upload id where no account could be associated with private uploads id: ${upload_id} ${primary_username} ${alternate_username}"
    fi
  fi
}

fix_users_duplicate_private_uploads_id_data()
{
  duplicate_users="$("${directory}/report_users_duplicate_private_uploads_id_data.sh" "${report_path}" | cut -d'|' -f1,2)"
  if [ ${#duplicate_users} -gt 0 ]; then
    echo "${duplicate_users}" | while read -r duplicate_user; do
      reset_users_private_uploads "${duplicate_user}"
    done
  fi

  upload_ids="$("${directory}/report_users_duplicate_private_uploads_id_data.sh" "${report_path}" | cut -d'|' -f9 | jq -r '.[]' | sort | uniq)"
  if [ ${#upload_ids} -gt 0 ]; then
    echo "${upload_ids}" | while read -r upload_id; do
      assign_users_upload_ids "${upload_id}"
    done
  fi
}

fix_users_duplicate_private_uploads_id_data
