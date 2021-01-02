#!/bin/bash -e

. _env.sh

. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate

cd ${PROJECT_ROOT_PATH}/src
export FLASK_DEBUG=1
export FLASK_APP=${PROJECT_ROOT_PATH}/src/endpoint.py
${PROJECT_ROOT_PATH}/dev_env/venv/bin/flask run --host 0.0.0.0
