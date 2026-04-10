#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/server"
docker-compose up -d
npm run start:dev
