#!/bin/bash
set -e

############## Definitions part
deploy_lambda_dependencies () {

    echo "Installing dependencies..."
    mkdir -p python/lib/python3.9/site-packages > /dev/null
    pip3 install -t ./python/lib/python3.9/site-packages -r "${INPUT_REQUIREMENTS_TXT}" > /dev/null
    echo "OK"

    echo "Zipping dependencies..."
    zip -r python.zip ./python > /dev/null
    rm -rf python > /dev/null
    echo "OK"

    echo "Publishing dependencies layer..."
    response=$(aws lambda publish-layer-version --compatible-runtimes python3.9 --layer-name "${INPUT_LAMBDA_LAYER_ARN}" --zip-file fileb://python.zip)
    VERSION=$(echo $response | jq '.Version')
    rm python.zip > /dev/null
    echo "OK"

    echo "Updating lambda layer version..."
    aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers "${INPUT_LAMBDA_LAYER_ARN}:${VERSION}" > /dev/null
    echo "OK"
    echo "Depencencies was deployed successfully"
}

############## Git config
git remote set-url origin "https://${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}"
CHANGED_FILES=()

############## Main part
echo "AWS configuration..."
aws configure set default.region "${INPUT_LAMBDA_REGION}" > /dev/null
echo "OK"

echo "Deploying lambda main code..."
zip -r lambda.zip . -x \*.git\* > /dev/null
aws lambda update-function-code --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --zip-file fileb://lambda.zip > /dev/null
echo "OK"

### Deploy dependencies if INPUT_LAMBDA_LAYER_ARN was defined in action call
[ ! -z "${INPUT_LAMBDA_LAYER_ARN}" ] && deploy_lambda_dependencies || echo "Dependencies wasn't deployed."

echo "${INPUT_LAMBDA_FUNCTION_NAME} function was deployed successfully."
