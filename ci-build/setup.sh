#!/bin/bash

# Constants
PROJECT_NAME="OktaIdx"
IDX_ROOT="${CI_DIRECTORY}"/..
DERIVED_DATA="${IDX_ROOT}/DerivedData"
DART_DIR="${HOME}/dart"
export LOGDIRECTORY=${DART_DIR}

if [[ -d "${DERIVED_DATA}" ]]; then
    rm -rf "${DERIVED_DATA}"
fi

if [[ -z ${WORKSPACE} ]]; then
    WORKSPACE="$HOME/okta"
fi

if [[ -z ${REPO} ]]; then
    REPO=${PROJECT_NAME}
fi

# Common environment variables

# Echos an error message
function echoError() {
  RED='\033[0;31m'
  NOCOLOR='\033[0m' #Default
  printf "${RED}${1}${NOCOLOR}\n"
  exit 1
}

# Echos a success message
function echoSuccess() {
  GREEN='\033[0;32m'
  NOCOLOR='\033[0m' #Default
  printf "${GREEN}${1}${NOCOLOR}\n"
}

function runTests() {
  echo "===================="
  echo "simulator test"
  xcodebuild -version
  pwd
  echo "===================="

  export TEST_SUITE_TYPE="junit"
  export TEST_RESULT_FILE_DIR="${DART_DIR}"

  echo ${TEST_SUITE_TYPE} > ${TEST_SUITE_TYPE_FILE}
  echo ${TEST_RESULT_FILE_DIR} > ${TEST_RESULT_FILE_DIR_FILE}

  if [[ $2 == "OktaSdk" ]]; then
    buildOktaSdk
  fi

  aws s3 --quiet --region us-east-1 cp s3://ci-secret-stash/test/devex/okta-idx-swift/TestCredentials.xcconfig $IDX_ROOT/TestCredentials.xcconfig
  xcodebuild -workspace $IDX_ROOT/okta-idx.xcworkspace -scheme $1 -destination "platform=iOS Simulator,name=iPhone 12" test

  FOUND_ERROR=$?

  ### Failure! One or other test suites exit non-zero
  if [[ "$FOUND_ERROR" -ne 0 ]] ; then
    echo "error: $FOUND_ERROR"
    return -1
  fi

  # Success!
  return 0
}

function buildOktaSdk() {
  echo "===================="
  echo "Building OktaSdk"
  pwd
  echo "===================="

  if [[ ! -d $IDX_ROOT/okta-sdk-swift/build/Release/OktaSdk.framework ]]; then
    git clone --depth 1 git@github.com:okta/okta-sdk-swift.git $IDX_ROOT/okta-sdk-swift
    (cd $IDX_ROOT/okta-sdk-swift; swift package resolve)
    xcodebuild -project $IDX_ROOT/okta-sdk-swift/OktaSdk.xcodeproj -target OktaSdk -sdk iphonesimulator -destination "destination=generic/iOS Simulator" build
    cp -r $IDX_ROOT/okta-sdk-swift/build/Release-iphonesimulator/AnyCodable.framework $IDX_ROOT/Samples/EmbeddedAuthWithSDKs/EmbeddedAuthUITests/ExternalDependencies
    cp -r $IDX_ROOT/okta-sdk-swift/build/Release-iphonesimulator/OktaSdk.framework $IDX_ROOT/Samples/EmbeddedAuthWithSDKs/EmbeddedAuthUITests/ExternalDependencies
  else
    echo "Skipping OktaSdk since it's already built locally"
  fi
}

# Print header with build machine, build launch information
function printBuildEnvironment() {
    USER=`whoami`
    HOST_NAME=`hostname`
    HOST_IP=`ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}'`
    OS_NAME=`sw_vers -productName`
    OS_VERSION=`sw_vers -productVersion`
    XCODE_VERSION=`xcodebuild -version | head -1 | awk '{print $2}'`
    RUBY_VERSION=`ruby -v | awk {'print $2'}`
    TIME_NOW=`date`
    UPTIME=`uptime`
    QUEUE=${SQS_QUEUE_URL}
    if [[ -z "$SHA" ]] ; then
        SHA=`git rev-parse  HEAD 2> /dev/null`
    fi
    if [[ -z "$BRANCH" ]] ; then
        BRANCH=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"`
    fi
    AUTHOR=`git show -s --pretty='%an'`
    COMMIT=`git show -s --pretty='%s'`
    COMMIT_DATE=`git show -s --pretty='%aD'`
    echo "====================================================="
    echo " Build  Launch"
    echo ""
    echo "  Time: $TIME_NOW"
    echo "Script: $SCRIPTNAME"
    echo "  Repo: $REPO"
    echo "Branch: $BRANCH"
    echo "   SHA: $SHA"
    echo "Author: $AUTHOR"
    echo "  Date: $COMMIT_DATE"
    echo "Commit: $COMMIT"
    echo "====================================================="
    echo " Build  Environment"
    echo ""
    echo "  Host: $HOST_NAME [$HOST_IP]"
    echo " Queue: $QUEUE"
    echo "  User: $USER"
    echo "    OS: $OS_NAME $OS_VERSION"
    echo " Xcode: $XCODE_VERSION"
    echo "  ruby: $RUBY_VERSION"
    echo "uptime: $UPTIME"
    echo "====================================================="
    echo "====================================================="
    echo " Test Details"
    echo "Device: "  ${DEVICE_NAME}
    echo "Test: "  ${TEST_GROUP}
    echo "====================================================="
}
