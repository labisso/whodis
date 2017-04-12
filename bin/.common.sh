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

function getEnvStatus() {
    aws elasticbeanstalk describe-environments --environment-name $1 \
        --query Environments[0].Status --output text
}

function getEnvUrl() {
    echo "http://$(aws elasticbeanstalk describe-environments --environment-name $1 \
    --query Environments[0].CNAME --output text)"
}

function echoBanner() {
    echo ""
    echo "***********************************************************************"
    echo $1
    echo "***********************************************************************"
}