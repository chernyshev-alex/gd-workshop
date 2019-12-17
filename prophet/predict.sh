#!/bin/bash

DAYS=${1:-365}

echo -e "building predictor and predict sequence to the next $DAYS days"
docker-compose build && docker-compose run package ipython apps/predict.py $DAYS
echo -e "Done"
