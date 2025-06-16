#!/bin/bash
set -uo pipefail

readonly DOC_DIAGNOSTIC_REGEX="^([^:]+):([0-9]+):[0-9]+: (warning|error): (.*)$"
readonly PWD_PREFIX="${PWD}/"

while IFS= read -r line; do
  echo "$line"

  if [[ "$line" =~ $DOC_DIAGNOSTIC_REGEX ]]; then
    full_path="${BASH_REMATCH[1]}"
    line_number="${BASH_REMATCH[2]}"
    severity="${BASH_REMATCH[3]}"
    message="${BASH_REMATCH[4]}"

    relative_path="${full_path#$PWD_PREFIX}"

    echo "::${severity} file=${relative_path},line=${line_number},title=Documentation ${severity}::${message}"
  fi
done
