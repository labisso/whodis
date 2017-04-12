#!/bin/bash -e

WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"

source $WHODIS_ROOT/bin/.common.sh


echoBanner "Emptying bucket and repository"
DEPLOY_BUCKET=$(getStackResourceId whodisDeployBucket)
aws s3 rm s3://${DEPLOY_BUCKET} --recursive
aws ecr delete-repository --force --repository-name whodis --output table

echoBanner "Destroying CloudFormation stack"
aws cloudformation delete-stack --stack-name whodis --output table

