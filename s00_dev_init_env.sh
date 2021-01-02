#!/bin/bash -e

. _env.sh

# clean up
cd ${PROJECT_ROOT_PATH}
rm -rf ${PROJECT_ROOT_PATH}/dev_env

# init folder
cd ${PROJECT_ROOT_PATH}
mkdir -p ${PROJECT_ROOT_PATH}/dev_env
mkdir -p ${PID_DIR_PATH}

# init local run env
cd ${PROJECT_ROOT_PATH}
python3 -m venv ${PROJECT_ROOT_PATH}/dev_env/venv
. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate
pip install --upgrade pip wheel
pip install yq awscli pytest
pip install -r ${PROJECT_ROOT_PATH}/src/requirements.txt

# download dynamodb local
cd ${PROJECT_ROOT_PATH}
curl https://s3.us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz -o ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz

# unzip dynamodb local
cd ${PROJECT_ROOT_PATH}
mkdir -p ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local
cd ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local
tar -xzf ${PROJECT_ROOT_PATH}/dev_env/dynamodb_local_latest.tar.gz
