#!/bin/bash -e

. _env.sh

MY_TMP_DIR_PATH=${PROJECT_ROOT_PATH}/dev.local.tmp

PUBLIC_COMPUTE_PORT=8000
PUBLIC_STATIC_PORT=8001
PUBLIC_DEPLOYGEN_PORT=8002
PUBLIC_MUTABLE_PORT=8003
PUBLIC_TMP_PORT=8004
DYNAMODB_PORT=8100

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${MY_TMP_DIR_PATH}/dynamodb.pid
kill_pid ${MY_TMP_DIR_PATH}/public-static.pid
kill_pid ${MY_TMP_DIR_PATH}/public-mutable.pid
kill_pid ${MY_TMP_DIR_PATH}/public-deploygen.pid
kill_pid ${MY_TMP_DIR_PATH}/public-tmp.pid
rm -rf ${MY_TMP_DIR_PATH}
mkdir -p ${MY_TMP_DIR_PATH}

# activate venv
. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate

# load env var
export STAGE=local
export CONF_PATH=${PROJECT_ROOT_PATH}/stages/${STAGE}
if [ -z ${GITPOD_REPO_ROOT+x} ]; then
  export PUBLIC_COMPUTE_URL_PREFIX="http://localhost:${PUBLIC_COMPUTE_PORT}"
  export PUBLIC_STATIC_URL_PREFIX="http://localhost:${PUBLIC_STATIC_PORT}"
  export PUBLIC_DEPLOYGEN_URL_PREFIX="http://localhost:${PUBLIC_DEPLOYGEN_PORT}"
  export PUBLIC_MUTABLE_URL_PREFIX="http://localhost:${PUBLIC_MUTABLE_PORT}"
  export PUBLIC_TMP_URL_PREFIX="http://localhost:${PUBLIC_TMP_PORT}"
else
  export PUBLIC_COMPUTE_URL_PREFIX=`gp url ${PUBLIC_COMPUTE_PORT}`
  export PUBLIC_STATIC_URL_PREFIX=`gp url ${PUBLIC_STATIC_PORT}`
  export PUBLIC_DEPLOYGEN_URL_PREFIX=`gp url ${PUBLIC_DEPLOYGEN_PORT}`
  export PUBLIC_MUTABLE_URL_PREFIX=`gp url ${PUBLIC_MUTABLE_PORT}`
  export PUBLIC_TMP_URL_PREFIX=`gp url ${PUBLIC_TMP_PORT}`
fi
export PUBLIC_STATIC_PATH=${PROJECT_ROOT_PATH}/public-static
export PUBLIC_DEPLOYGEN_PATH=${PROJECT_ROOT_PATH}/deploygen.tmp/public
export PUBLIC_MUTABLE_PATH=${MY_TMP_DIR_PATH}/public-mutable
export PUBLIC_TMP_PATH=${MY_TMP_DIR_PATH}/public-tmp
export PRIVATE_STATIC_PATH=${PROJECT_ROOT_PATH}/private-static
export PRIVATE_DEPLOYGEN_PATH=${PROJECT_ROOT_PATH}/deploygen.tmp/private
export PRIVATE_MUTABLE_PATH=${MY_TMP_DIR_PATH}/private-mutable
export PRIVATE_TMP_PATH=${MY_TMP_DIR_PATH}/private-tmp
export DB_TABLE_NAME=tmp_table
export DYNAMODB_ENDPOINT_URL="http://localhost:${DYNAMODB_PORT}"
export DYNAMODB_REGION=`jq -r  .AWS_REGION ${PROJECT_ROOT_PATH}/stages/local/conf.json`

# for runtime
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export FLASK_RUN_PORT=${PUBLIC_COMPUTE_PORT}
export FUTSU_GCP_ENABLE=0

# update dynamodb local
mkdir -p ${MY_TMP_DIR_PATH}
curl https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz.sha256 -o ${MY_TMP_DIR_PATH}/dynamodb_local_latest.tar.gz.sha256
TMP0=`cat ${MY_TMP_DIR_PATH}/dynamodb_local_latest.tar.gz.sha256 | awk '{print $1}'`
TMP1=1 ; echo "${TMP0} ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz" | sha256sum -c - || TMP1=$?
if [ "${TMP1}" != "0" ]; then
  rm -f ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz
  curl https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz -o ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz
fi
echo "${TMP0} ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz" | sha256sum -c -

# unzip dynamodb local
cd ${PROJECT_ROOT_PATH}
mkdir -p ${MY_TMP_DIR_PATH}/dynamodb_local
cd ${MY_TMP_DIR_PATH}/dynamodb_local
tar -xzf ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz

# run dynamodb local
cd ${MY_TMP_DIR_PATH}
java -Djava.library.path=./dynamodb_local/DynamoDBLocal_lib -jar dynamodb_local/DynamoDBLocal.jar -inMemory -port ${DYNAMODB_PORT} &
echo $! > dynamodb.pid

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

# deploygen
cd ${PROJECT_ROOT_PATH}
${PROJECT_ROOT_PATH}/_gen_deploygen.sh ${STAGE}

# emulate bucket
cd ${PROJECT_ROOT_PATH}
mkdir -p ${PUBLIC_MUTABLE_PATH}
mkdir -p ${PUBLIC_TMP_PATH}
mkdir -p ${PRIVATE_MUTABLE_PATH}
mkdir -p ${PRIVATE_TMP_PATH}
python -m http.server ${PUBLIC_STATIC_PORT}    --directory ${PUBLIC_STATIC_PATH} &
echo $! > ${MY_TMP_DIR_PATH}/public-static.pid
python -m http.server ${PUBLIC_DEPLOYGEN_PORT}   --directory ${PUBLIC_DEPLOYGEN_PATH} &
echo $! > ${MY_TMP_DIR_PATH}/public-deploygen.pid
python -m http.server ${PUBLIC_MUTABLE_PORT} --directory ${PUBLIC_MUTABLE_PATH} &
echo $! > ${MY_TMP_DIR_PATH}/public-mutable.pid
python -m http.server ${PUBLIC_TMP_PORT}       --directory ${PUBLIC_TMP_PATH} &
echo $! > ${MY_TMP_DIR_PATH}/public-tmp.pid

# local run
cd ${PROJECT_ROOT_PATH}/src
export FLASK_DEBUG=1
export FLASK_APP=${PROJECT_ROOT_PATH}/src/endpoint.py
${PROJECT_ROOT_PATH}/dev_env/venv/bin/flask run --host 0.0.0.0

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${MY_TMP_DIR_PATH}/dynamodb.pid
kill_pid ${MY_TMP_DIR_PATH}/public-static.pid
kill_pid ${MY_TMP_DIR_PATH}/public-mutable.pid
kill_pid ${MY_TMP_DIR_PATH}/public-deploygen.pid
kill_pid ${MY_TMP_DIR_PATH}/public-tmp.pid
rm -rf ${MY_TMP_DIR_PATH}
