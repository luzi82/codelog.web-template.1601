#!/bin/bash -e

. _env.sh

MY_TMP_DIR_PATH=${LOCAL_TMP_DIR_PATH}
MY_VAR_DIR_PATH=${LOCAL_VAR_DIR_PATH}

# activate venv
. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${MY_TMP_DIR_PATH}/dynamodb.pid
kill_pid ${MY_TMP_DIR_PATH}/public-static.pid
kill_pid ${MY_TMP_DIR_PATH}/public-mutable.pid
kill_pid ${MY_TMP_DIR_PATH}/public-deploygen.pid
kill_pid ${MY_TMP_DIR_PATH}/public-tmp.pid
rm -rf ${MY_TMP_DIR_PATH}
mkdir -p ${MY_TMP_DIR_PATH}

# local var
PUBLIC_COMPUTE_PORT=${LOCAL_PUBLIC_COMPUTE_PORT}
PUBLIC_STATIC_PORT=${LOCAL_PUBLIC_STATIC_PORT}
PUBLIC_DEPLOYGEN_PORT=${LOCAL_PUBLIC_DEPLOYGEN_PORT}
PUBLIC_MUTABLE_PORT=${LOCAL_PUBLIC_MUTABLE_PORT}
PUBLIC_TMP_PORT=${LOCAL_PUBLIC_TMP_PORT}
DYNAMODB_PORT=${LOCAL_DYNAMODB_PORT}

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
export FLASK_DEBUG=1
export FLASK_APP=${PROJECT_ROOT_PATH}/src/endpoint.py
export PYTHONPATH=${PROJECT_ROOT_PATH}/src

# run dynamodb local
cd ${PROJECT_ROOT_PATH}
java \
  -Djava.library.path=${PROJECT_ROOT_PATH}/dev_env/dynamodb_local/DynamoDBLocal_lib \
  -jar ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local/DynamoDBLocal.jar \
  -dbPath ${MY_VAR_DIR_PATH}/dynamodb.data \
  -port ${DYNAMODB_PORT} \
  &
echo $! > ${MY_TMP_DIR_PATH}/dynamodb.pid

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
${PROJECT_ROOT_PATH}/dev_env/venv/bin/flask run --host 0.0.0.0

# clean up
cd ${PROJECT_ROOT_PATH}
kill_pid ${MY_TMP_DIR_PATH}/dynamodb.pid
kill_pid ${MY_TMP_DIR_PATH}/public-static.pid
kill_pid ${MY_TMP_DIR_PATH}/public-mutable.pid
kill_pid ${MY_TMP_DIR_PATH}/public-deploygen.pid
kill_pid ${MY_TMP_DIR_PATH}/public-tmp.pid
rm -rf ${MY_TMP_DIR_PATH}
