#!/bin/bash -e

. _env.sh

cd ${PROJECT_ROOT_PATH}
rm -rf ${PROJECT_ROOT_PATH}/aws_env
mkdir -p ${PROJECT_ROOT_PATH}/aws_env

cd ${PROJECT_ROOT_PATH}/aws_env
ln -s ${PROJECT_ROOT_PATH}/aws/package.json ${PROJECT_ROOT_PATH}/aws_env/
ln -s ${PROJECT_ROOT_PATH}/aws/package-lock.json ${PROJECT_ROOT_PATH}/aws_env/
npm install
SERVERLESS=${PROJECT_ROOT_PATH}/aws_env/node_modules/.bin/serverless
${SERVERLESS} --version

cd ${PROJECT_ROOT_PATH}/aws_env
python3 -m venv ${PROJECT_ROOT_PATH}/aws_env/venv
. ${PROJECT_ROOT_PATH}/aws_env/venv/bin/activate
pip install --upgrade pip wheel
#pip install awscli
if [[ ! -e ${PROJECT_ROOT_PATH}/aws_env/venv/bin/python3.7 ]]; then
  ln -s ${PROJECT_ROOT_PATH}/aws_env/venv/bin/python3 ${PROJECT_ROOT_PATH}/aws_env/venv/bin/python3.7
fi
