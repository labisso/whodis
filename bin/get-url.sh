#!/bin/bash -e

WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"

source $WHODIS_ROOT/bin/.common.sh

EB_ENVIRONMENT=$(getStackResourceId whodisEnvironment)

getEnvUrl $EB_ENVIRONMENT