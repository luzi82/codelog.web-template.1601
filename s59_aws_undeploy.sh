#!/bin/bash -e

. _env.sh

if [ -z ${STAGE+x} ]; then export STAGE=dev; fi

MY_TMP_DIR_PATH=${PROJECT_ROOT_PATH}/aws.undeploy.tmp
rm -rf ${MY_TMP_DIR_PATH}
mkdir -p ${MY_TMP_DIR_PATH}

SERVERLESS=${PROJECT_ROOT_PATH}/aws_env/node_modules/.bin/serverless
${SERVERLESS} --version

. ${PROJECT_ROOT_PATH}/aws_env/venv/bin/activate

cd ${MY_TMP_DIR_PATH}
cp ${PROJECT_ROOT_PATH}/aws/serverless.yml ${MY_TMP_DIR_PATH}/
${SERVERLESS} remove --stage ${STAGE} -v
${SERVERLESS} delete_domain --stage ${STAGE}

cd ${PROJECT_ROOT_PATH}
rm -rf ${MY_TMP_DIR_PATH}
