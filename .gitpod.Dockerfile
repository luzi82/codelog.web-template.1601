FROM debian:10.6

# Install custom tools, runtimes, etc.
# For example "bastet", a command-line tetris clone:
# RUN brew install bastet
#
# More information: https://www.gitpod.io/docs/config-docker/

USER root

# apt-get blah
RUN true \
 && apt-get update \
 && apt-get install -y \
    curl \
    jq \
    openjdk-11-jre \
    procps \
    python3.7 \
    python3-venv

# install nodejs
RUN true \
 && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
 && apt-get update \
 && apt-get install -y \
    nodejs
