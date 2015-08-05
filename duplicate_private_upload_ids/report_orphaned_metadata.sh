#!/bin/bash -eu

# Requires: mongo, jq

if [ -z "$(which mongo)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, jq" >&2
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
    SEAGULL_DATABASE="seagull"
    ;;
  test)
    MONGO_OPTIONS="--quiet"
    SEAGULL_DATABASE="seagull"
    ;;
  local)
    MONGO_OPTIONS="--quiet"
    SEAGULL_DATABASE="user"
    ;;
  *)
    echo "ERROR: First argument must be environment: production, staging, development, test, local" >&2
    exit 1
esac

# Report path
if [ -z "${2:-}" ]; then
  echo "ERROR: Second argument must be the output file from report_users.sh" >&2
  exit 1
else
  report_path="${2}"
fi

report_orphaned_metadata()
{
  unset metadata_ids
  unset metadata_id

  metadata_ids="$(mongo ${MONGO_OPTIONS} ${SEAGULL_DATABASE} --eval "printjson(db.seagull.distinct(\"_id\", {\"_id\": {\$exists: true}}))" | jq -r '.[]')"
  for metadata_id in ${metadata_ids}; do
    unset count

    count="$(egrep -c "^[^\|]+\|[^\|]+\|${metadata_id}\|" "${report_path}")"
    if [ ${count} -lt 1 ]; then
      echo "WARN: Orphaned metadata with _id: ${metadata_id}"
    fi
  done
}

report_orphaned_metadata
