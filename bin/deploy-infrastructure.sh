#!/bin/bash -e

WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"

USER_ARN="$(aws iam get-user --output text --query 'User.Arn')"

aws cloudformation deploy --template-file ${WHODIS_ROOT}/deploy/cf/whodis.yml \
    --stack-name whodis --capabilities CAPABILITY_IAM \
    --parameter-overrides IamUser=${USER_ARN}