#!/bin/bash -e

if [ $# -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 VERSION"
    echo "    VERSION: a string used to identify the version"
    exit 1
fi

VERSION=$1
WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"
STACK_NAME="whodis"


function getStackResourceId() {
    set +e
    aws --output json cloudformation describe-stack-resources --stack-name ${STACK_NAME} \
        --logical-resource-id $1 --output text --query 'StackResources[].PhysicalResourceId'
    if [ $? -ne 0 ]; then
        echo "Stack resource not found. Did you deploy the infrastructure?" >&2
        exit 1
    fi
    set -e
}

function echoBanner() {
    echo ""
    echo "***********************************************************************"
    echo $1
    echo "***********************************************************************"
}

APP_NAME=$(getStackResourceId whodis)
DEPLOY_BUCKET=$(getStackResourceId whodisDeployBucket)
EB_ENVIRONMENT=$(getStackResourceId whodisEnvironment)

VERSION_EXISTS=$(aws elasticbeanstalk describe-application-versions \
    --application-name ${APP_NAME} --version-labels ${VERSION} \
    --query ApplicationVersions --output text)

if [ ! -z "${VERSION_EXISTS}" ]; then
    echo "Version ${VERSION} already exists. Deploying it."

else

    # this executes a docker login command for the ECR repo
    eval $(aws ecr get-login)

    DOCKER_REPO_NAME=$(aws ecr describe-repositories --repository-names whodis \
         --output text --query 'repositories[0].repositoryUri')
    IMAGE_AND_VERSION="$DOCKER_REPO_NAME:$VERSION"

    echoBanner "Pushing whodis Docker image"
    docker build -t whodis:$VERSION .
    docker tag whodis:$VERSION $IMAGE_AND_VERSION
    docker push $IMAGE_AND_VERSION


    echoBanner "Pushing Elastic Beanstalk manifest"
    (cd $WHODIS_ROOT/deploy/eb &&
        sed "s|\${IMAGE_AND_VERSION}|${IMAGE_AND_VERSION}|" Dockerrun.aws.json.template > Dockerrun.aws.json &&
        zip deployment-${VERSION}.zip -r Dockerrun.aws.json &&
        aws s3 cp deployment-${VERSION}.zip s3://${DEPLOY_BUCKET}/)

    aws elasticbeanstalk create-application-version --application-name ${APP_NAME} \
        --source-bundle S3Bucket=${DEPLOY_BUCKET},S3Key=deployment-${VERSION}.zip \
        --version-label ${VERSION} --output table
fi


echoBanner "Updating Elastic Beanstalk environment"
aws elasticbeanstalk update-environment --version-label ${VERSION} \
    --environment-name ${EB_ENVIRONMENT} --output table
