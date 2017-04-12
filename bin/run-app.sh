#!/bin/bash -e

WHODIS_ROOT="$(dirname "$(dirname "$(readlink "$0")")")"
source $WHODIS_ROOT/bin/.common.sh

cd $WHODIS_ROOT

if [ -z "$WHODIS_PORT" ]; then
    WHODIS_PORT="8080"
fi

echoBanner "Building Docker image"
docker build -t whodis .

echoBanner "Running whodis container: http://localhost:$WHODIS_PORT"
docker run --rm -it -p${WHODIS_PORT}:80 whodis:latest
