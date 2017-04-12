#!/bin/bash -e

if [ $# -gt 1 ]; then
    echo "Usage: $0 [VERSION]"
    echo "    VERSION: a string used to identify the version"
    exit 1
fi

VERSION=$1
WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"

if [ -z "$VERSION"]; then
    VERSION=$(date +%s)
fi

source $WHODIS_ROOT/bin/.common.sh

APP_NAME=$(getStackResourceId whodis)
DEPLOY_BUCKET=$(getStackResourceId whodisDeployBucket)
EB_ENVIRONMENT=$(getStackResourceId whodisEnvironment)

echoBanner "Deploying version ${VERSION}"

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


echoBanner "Waiting for environment to be ready"
let attempts=1
until [[ "$(getEnvStatus ${EB_ENVIRONMENT})" = "Ready" ]]; do
    if [[ $attempt_num -ge 60 ]]; then
        echo "Timed out waiting for environment to be ready. Did deploy fail?"
        exit 1
    else
        sleep 10
        attempts=`expr $attempts + 1`
    fi
done


echoBanner "Successfully deployed to: $(getEnvUrl $EB_ENVIRONMENT)"