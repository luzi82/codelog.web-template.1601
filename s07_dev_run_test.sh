#!/bin/bash -e

. _env.sh

. ${PROJECT_ROOT_PATH}/dev_env/venv/bin/activate

export PYTHONPATH=${PROJECT_ROOT_PATH}/src
pytest -v -s
