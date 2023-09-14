#!/usr/bin/env bash

set -e -u

docker compose -f local/docker-compose.yml exec "$@"
