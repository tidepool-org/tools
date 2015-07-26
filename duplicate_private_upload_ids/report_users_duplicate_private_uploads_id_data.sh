#!/bin/bash -eu

# Report path
if [ -z "${1:-}" ]; then
  echo "ERROR: First argument must be the output file from report_users.sh" >&2
  exit 1
else
  report_path="${1}"
fi

egrep -v "\|0\|0\|\|$" "${report_path}" | cut -d'|' -f5 | sort | uniq -d | tr "\\n" "|" | sed 's/\(.*\)|$/\1/' | xargs -I MATCH egrep "^[^\|]+\|[^\|]+\|[^\|]+\|[^\|]+\|(MATCH)\|" "${report_path}"
