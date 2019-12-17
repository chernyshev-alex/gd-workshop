#!/bin/bash

ZK="--zookeeper zookeeper:2181"
REST_API="http://localhost:8083"
KSQL_API="http://ksql-server:8088"
ELK_API="http://localhost:9200"
INDEX=market
INDEX_TYPE=tx

# start all services
docker-compose up -d --build

echo -e "\nWaiting connector service"
while [ "$(docker-compose ps | grep connect | awk '{print $4}')" != '(healthy)' ]; do
  printf '.'; sleep 5
done

echo -e "\nCreating topics"
docker-compose exec broker kafka-topics --create $ZK --replication-factor 1 --partitions 1 --topic stocks-csv   
docker-compose exec broker kafka-topics --create $ZK --replication-factor 1 --partitions 1 --topic predictions 

# create index in ELK
echo -e "\nELK :  creating index - $INDEX"
curl -s -X PUT $ELK_API/$INDEX/

echo -e "\nCreating mapping in $INDEX"
# grahana requires mapping to discover tmestamp field
curl -s -X PUT $ELK_API/$INDEX/_mapping/$INDEX_TYPE -H "Content-Type: application/json" \
  -d '{ "properties": { "DT": { "type": "date" },"TICKER": { "type": "text" },"CLOSED": { "type": "double" }}}'

echo -e "\nDeploying connectors"
curl -d '@./connect/elk-sink.json' -H "Content-Type: application/json" -X POST $REST_API/connectors

echo -e "\nDeployed connectors are :"
curl $REST_API/connectors 

echo -e "\nCreating streams/tables"
docker-compose exec -T ksql-cli ksql $KSQL_API <<EOF
  run scripts '/ksql/init.sql';
  exit ;
EOF


