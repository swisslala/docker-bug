#!/bin/bash
set -e pipefail

# finally build the main one
docker build --force-rm -f Dockerfile -t docker-test:final .
