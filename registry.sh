#!/bin/sh

docker run \
  -e SETTINGS_FLAVOR=local \
  -e STORAGE_PATH=/registry-data \
  -e SEARCH_BACKEND=sqlalchemy \
  -v /registry-data:/registry-data \
  -p 5000:5000 \
  registry
