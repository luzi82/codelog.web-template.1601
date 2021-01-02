#!/bin/bash -e

export STAGE="sample"

TMP_DIR=`mktemp -d`
trap 'rm -rf "${TMP_DIR}"' EXIT

SM_URL=https://raw.githubusercontent.com/luzi82/luzi82.secret
SM_BRANCH=codelog.flask.sample.ci
curl ${SM_URL}/${SM_BRANCH}/secret.tar.gz.gpg.sig \
  -o ${TMP_DIR}/secret.tar.gz.gpg.sig

gpg --no-default-keyring --keyring sample-ci/public-key.gpg --verify ${TMP_DIR}/secret.tar.gz.gpg.sig

gpg --no-default-keyring --keyring sample-ci/public-key.gpg --decrypt ${TMP_DIR}/secret.tar.gz.gpg.sig | \
gpg --quiet --batch --yes --decrypt --passphrase="${SAMPLE_CI_SECRET}" | \
tar xzf -

. secret/env.sh

cp sample-ci/conf.json conf/conf.json

./s50_aws_init_env.sh
./s58_aws_deploy.sh
