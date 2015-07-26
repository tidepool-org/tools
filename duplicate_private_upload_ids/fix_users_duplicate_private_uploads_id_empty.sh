#!/bin/bash -eu

# Environment
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be environment: prod, staging, devel, test, local" >&2
  exit 1
else
  environment="${1}"
fi
case "${environment}" in
  prod|staging|devel|test|local)
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

fix_users_duplicate_private_uploads_id_empty()
{
  duplicate_users="$("${directory}/report_users_duplicate_private_uploads_id_empty.sh" "${report_path}" | cut -d'|' -f1,2)"
  if [ ${#duplicate_users} -gt 0 ]; then
    echo "${duplicate_users}" | while read -r duplicate_user; do
      reset_users_private_uploads "${duplicate_user}"
    done
  fi
}

fix_users_duplicate_private_uploads_id_empty
