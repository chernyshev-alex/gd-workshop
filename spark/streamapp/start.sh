#!/bin/bash

set -e

echo -e "\nassembly app and building  image.."
sbt assembly && docker build -f Dockerfile-app -t workshop/streamapp:latest .

[ $? -eq 0 ]  || exit 1

echo -e "\nbuilding spark image.."
docker build -f Dockerfile-spark -t workshop/spark:latest .

echo -e "\n start spark"
docker-compose up -d 

open "http://localhost:8080/"

docker-compose logs -f

