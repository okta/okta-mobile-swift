#!/bin/bash

set -x

# Setup CI Variables

CI_DIRECTORY=$(cd `dirname $0` && pwd)
source "${CI_DIRECTORY}/setup.sh"
pushd "${IDX_ROOT}"

# Main
pushd "${IDX_ROOT}"
printBuildEnvironment
# set -e
runTests "okta-idx-ios"
if [[ $? -ne 0 ]]; then
  echo "Error running tests"
  exit -1
else
  exit 0
fi
