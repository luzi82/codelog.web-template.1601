#!/bin/bash -e

. _env.sh

bad_exit(){
    echo "${0} stage"
    exit 1
}

# args
ARG_STAGE=${1}
if [ ! -f "stages/${ARG_STAGE}/conf.json" ]; then
    bad_exit
fi

STAGE=${ARG_STAGE}

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
