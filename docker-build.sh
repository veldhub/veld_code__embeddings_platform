#!/bin/bash

read -r tag_latest tag_date <<< "$(./docker-create_tag.sh)"

docker build . -t "$tag_latest"
docker build . -t "$tag_date"

