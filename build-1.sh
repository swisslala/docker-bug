#!/bin/bash
set -e pipefail

docker build --force-rm -f Dockerfile-builder -t docker-test:builder .
docker build --force-rm -f Dockerfile-base -t docker-test:base .