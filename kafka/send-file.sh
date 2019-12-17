#!/bin/bash

sleep_time=${1:-5}
filename=${2:-../data/aapl.csv}

while read -r line; do
    echo "$line";
    sleep $sleep_time
done < "$filename" | docker-compose exec -T broker kafka-console-producer --broker-list broker:9092 -topic stocks-csv -
