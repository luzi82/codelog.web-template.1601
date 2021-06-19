#!/bin/bash -e

. _env.sh

if [ -z ${STAGE+x} ]; then export STAGE=dev; fi

MY_TMP_DIR_PATH=${PROJECT_ROOT_PATH}/aws.deploy.tmp
rm -rf ${MY_TMP_DIR_PATH}
mkdir -p ${MY_TMP_DIR_PATH}

SERVERLESS=${PROJECT_ROOT_PATH}/aws_env/node_modules/.bin/serverless
${SERVERLESS} --version

. ${PROJECT_ROOT_PATH}/aws_env/venv/bin/activate

cd ${PROJECT_ROOT_PATH}/src
cp ${PROJECT_ROOT_PATH}/src/requirements.txt ${MY_TMP_DIR_PATH}/
cp --parents `find -name \*.py` ${MY_TMP_DIR_PATH}/
cp --parents `find -name \*.tmpl` ${MY_TMP_DIR_PATH}/

cd ${MY_TMP_DIR_PATH}
cp ${PROJECT_ROOT_PATH}/aws/serverless.yml ${MY_TMP_DIR_PATH}/
${SERVERLESS} create_domain --stage ${STAGE}
${SERVERLESS} deploy --stage ${STAGE} -v

cd ${PROJECT_ROOT_PATH}
rm -rf ${MY_TMP_DIR_PATH}
