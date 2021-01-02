#!/bin/bash -e

. _env.sh

export STAGE=local
MY_TMP_DIR_PATH=${LOCAL_TMP_DIR_PATH}
MY_VAR_DIR_PATH=${LOCAL_VAR_DIR_PATH}

# activate venv for yq
. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${PID_DIR_PATH}/${STAGE}.dynamodb.pid
mkdir -p ${MY_TMP_DIR_PATH}

# local var
DYNAMODB_PORT=${LOCAL_DYNAMODB_PORT}
DB_TABLE_NAME=tmp_table
DYNAMODB_ENDPOINT_URL="http://localhost:${DYNAMODB_PORT}"
DYNAMODB_REGION=`jq -r  .AWS_REGION ${PROJECT_ROOT_PATH}/stages/local/conf.json`

# for runtime
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# run dynamodb local
cd ${PROJECT_ROOT_PATH}
rm -rf ${MY_VAR_DIR_PATH}/dynamodb.data
mkdir -p ${MY_VAR_DIR_PATH}/dynamodb.data
java \
  -Djava.library.path=${PROJECT_ROOT_PATH}/dev_env/dynamodb_local/DynamoDBLocal_lib \
  -jar ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local/DynamoDBLocal.jar \
  -dbPath ${MY_VAR_DIR_PATH}/dynamodb.data \
  -port ${DYNAMODB_PORT} \
  &
echo $! > ${PID_DIR_PATH}/${STAGE}.dynamodb.pid

# load dynamodb setting
cd ${PROJECT_ROOT_PATH}
yq -cM .resources.Resources.Db.Properties.AttributeDefinitions   ${PROJECT_ROOT_PATH}/aws/serverless.yml | tr -d '\n' > ${MY_TMP_DIR_PATH}/db.AttributeDefinitions
yq -cM .resources.Resources.Db.Properties.KeySchema              ${PROJECT_ROOT_PATH}/aws/serverless.yml | tr -d '\n' > ${MY_TMP_DIR_PATH}/db.KeySchema
yq -cM .resources.Resources.Db.Properties.GlobalSecondaryIndexes ${PROJECT_ROOT_PATH}/aws/serverless.yml | tr -d '\n' > ${MY_TMP_DIR_PATH}/db.GlobalSecondaryIndexes
yq -r  .resources.Resources.Db.Properties.BillingMode            ${PROJECT_ROOT_PATH}/aws/serverless.yml | tr -d '\n' > ${MY_TMP_DIR_PATH}/db.BillingMode

# create table
cd ${PROJECT_ROOT_PATH}
aws dynamodb create-table \
    --table-name tmp_table \
    --attribute-definitions file://${MY_TMP_DIR_PATH}/db.AttributeDefinitions \
    --key-schema file://${MY_TMP_DIR_PATH}/db.KeySchema \
    --global-secondary-indexes file://${MY_TMP_DIR_PATH}/db.GlobalSecondaryIndexes \
    --billing-mode file://${MY_TMP_DIR_PATH}/db.BillingMode \
    --endpoint-url "${DYNAMODB_ENDPOINT_URL}" \
    --region "${DYNAMODB_REGION}"
aws dynamodb wait table-exists \
    --table-name tmp_table \
    --endpoint-url "${DYNAMODB_ENDPOINT_URL}" \
    --region "${DYNAMODB_REGION}"

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${PID_DIR_PATH}/${STAGE}.dynamodb.pid
