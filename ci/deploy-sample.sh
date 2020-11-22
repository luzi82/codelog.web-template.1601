#!/bin/bash

export STAGE="sample"

TMP_FILE=`mktemp`
trap "{ rm -f ${TMP_FILE}; }" EXIT

curl https://raw.githubusercontent.com/luzi82/codelog.flask.ci.secret/sample-ci/secret.tar.gz.gpg.sig -o ${TMP_FILE}
gpg --no-default-keyring --keyring ${PWD}/ci/sample-public-key.gpg --verify ${TMP_FILE}
gpg --no-default-keyring --keyring ${PWD}/ci/sample-public-key.gpg --decrypt ${TMP_FILE} | \
gpg --quiet --batch --yes --decrypt --passphrase="${SAMPLE_CI_SECRET}" | \
tar xzf -

. secret/env.sh

./aws-deploy.sh