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

MY_TMP_DIR_PATH=${PROJECT_ROOT_PATH}/aws.deploy.tmp
rm -rf ${MY_TMP_DIR_PATH}
mkdir -p ${MY_TMP_DIR_PATH}

SERVERLESS=${PROJECT_ROOT_PATH}/aws_env/node_modules/.bin/serverless
${SERVERLESS} --version

. ${PROJECT_ROOT_PATH}/aws_env/venv/bin/activate

# clone compute file
cd ${PROJECT_ROOT_PATH}/src
cp ${PROJECT_ROOT_PATH}/src/requirements.txt ${MY_TMP_DIR_PATH}/
cp --parents `find -name \*.py` ${MY_TMP_DIR_PATH}/
cp --parents `find -name \*.tmpl` ${MY_TMP_DIR_PATH}/

# deploygen
cd ${PROJECT_ROOT_PATH}
${PROJECT_ROOT_PATH}/_gen_deploygen.sh ${STAGE}

# deploy
cd ${MY_TMP_DIR_PATH}
cp ${PROJECT_ROOT_PATH}/aws/serverless.yml ${MY_TMP_DIR_PATH}/
${SERVERLESS} --stage ${STAGE} create_domain
${SERVERLESS} --stage ${STAGE} deploy -v

cd ${PROJECT_ROOT_PATH}
rm -rf ${MY_TMP_DIR_PATH}
