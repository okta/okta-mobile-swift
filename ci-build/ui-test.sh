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

# Disable hardware keyboard, which causes problems with some tests
killall Simulator
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

runTests "EmbeddedAuth" "OktaSdk"
if [[ $? -ne 0 ]]; then
  echo "Error running tests"
  exit -1
else
  exit 0
fi
