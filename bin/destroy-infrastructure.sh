#!/bin/bash -e

WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"

source $WHODIS_ROOT/bin/.common.sh

echoBanner "Destroying CloudFormation stack"
aws cloudformation delete-stack --stack-name whodis --output table \
    --retain-resources "whodisDockerRepository" "whodisDeployBucket"

