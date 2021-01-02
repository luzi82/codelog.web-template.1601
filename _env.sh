#!/bin/bash -e

PROJECT_ROOT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

LOCAL_PUBLIC_COMPUTE_PORT=8000
LOCAL_PUBLIC_STATIC_PORT=8001
LOCAL_PUBLIC_DEPLOYGEN_PORT=8002
LOCAL_PUBLIC_MUTABLE_PORT=8003
LOCAL_PUBLIC_TMP_PORT=8004
LOCAL_DYNAMODB_PORT=8100

# fuck gitpod
unset PIPENV_VENV_IN_PROJECT
unset PIP_USER
unset PYTHONUSERBASE

kill_pid() {
  if [ -f "$1" ];then
    kill `cat $1` || true
    rm $1
  fi
}
