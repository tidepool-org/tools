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

# Report path
if [ -z "${2:-}" ]; then
  echo "ERROR: Second argument must be the output file from report_users.sh" >&2
  exit 1
else
  report_path="${2}"
fi

report_orphaned_device_data_by_field()
{
  unset field
  unset private_uploads_ids
  unset private_uploads_id

  field="${1}"

  private_uploads_ids="$(mongo ${MONGO_OPTIONS} ${DEVICEDATA_DATABASE} --eval "printjson(db.deviceData.distinct(\"${field}\", {\"${field}\": {\$exists: true}}))" | jq -r '.[]')"
  if [ ${#private_uploads_ids} -gt 0 ]; then
    echo "${private_uploads_ids}" | while read -r private_uploads_id; do
      unset count

      count="$(egrep -c "^[^\|]+\|[^\|]+\|[^\|]+\|[^\|]+\|${private_uploads_id}\|" "${report_path}")"
      if [ ${count} -lt 1 ]; then
        echo "WARN: Orphaned device data with ${field}: ${private_uploads_id}"
      fi
    done
  fi
}

report_orphaned_device_data()
{
  report_orphaned_device_data_by_field "_groupId"
  report_orphaned_device_data_by_field "groupId"
}

report_orphaned_device_data
