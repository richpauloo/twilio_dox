#!/bin/bash

echo "Build the docker"

docker build . -t docker.io/richpauloo/tdox:prod.0.0.01

# if [[ the last exit code $? indicates a successful 0 build, then
if [[ $? = 0 ]] ; then
echo "Pushing docker..."
docker push docker.io/richpauloo/tdox:prod.0.0.01
else
echo "Docker build failed"
fi
