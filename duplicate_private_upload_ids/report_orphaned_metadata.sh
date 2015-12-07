#!/bin/bash -eu

# Requires: mongo, jq

if [ -z "$(which mongo)" -o -z "$(which jq)" ]; then
  echo "ERROR: Required tools: mongo, jq" >&2
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
    SEAGULL_DATABASE="seagull"
    ;;
  test)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    SEAGULL_DATABASE="seagull"
    ;;
  local)
    MONGO_OPTIONS="${MONGO_OPTIONS:-} --quiet"
    SEAGULL_DATABASE="user"
    ;;
  *)
    echo "ERROR: First argument must be environment: prd, stg, dev, test, local" >&2
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
  if [ ${#metadata_ids} -gt 0 ]; then
    echo "${metadata_ids}" | while read -r metadata_id; do
      unset count

      count="$(egrep -c "^[^\|]+\|[^\|]+\|${metadata_id}\|" "${report_path}")"
      if [ ${count} -lt 1 ]; then
        echo "WARN: Orphaned metadata with _id: ${metadata_id}"
      fi
    done
  fi
}

report_orphaned_metadata
