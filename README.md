# Workshop : Automatic Stocks Forecasting  

status : DRAFT v1.0

## Important links

- Workshop Presentation: https://docs.google.com/presentation/d/1PaidQgd6Q6-WKm_R4Xbzmb_MDn0M1fXZVAeX5F_wHWU/edit#slide=id.p
- Kafka: https://www.confluent.io/
- Spark Structured Streaming: https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#basic-operations---selection-projection-aggregation
- Prophet: https://facebook.github.io/prophet/
- Grafana: https://grafana.com/docs/features/datasources/elasticsearch/
- Elastic Search: https://www.elastic.co/guide/en/elasticsearch/reference/6.4/index.html

## Prerequisites  
- 
- Docker version >= 19.03.0, Docker composer >=1.24.0
- curl or postman
- [Java 8 JDK]  (https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
- [Scala] (https://www.scala-lang.org/download/)  
- [Scala IDE for Eclipse 4.7.0] (http://scala-ide.org/)  or IDEA Scala
- 

## Install

brew install docker docker-composer java8-jdk scala curl postman ammonite-repl git

### Check docker versions

```
$ docker --version
Docker version 19.03
$ docker-compose --version
docker-compose version 1.24.1
$ docker-machine --version
docker-machine version 0.16.0
$ docker run hello-world
Hello from Docker!
```

### Checkout workshop
git clone https://github.com/chernyshev-alex/kafka-workshop.git

Go to kafka/ksql/init.sql and follow instructions


### Additional questions

```
ksql> show topics;
1. Q : read topic 'stocks' content  ?  A : print 'stocks' from beginning; 
2. Q : read 4 records from stream ?  A : select * from stocks limit 4; 
3. Q : Get all streams ? A : show streams; 
4. Q : Which is format of stream PREDICTIONS ? A : AVRO
5. Q : Get columns, types of stocks stream ? A : describe extended stocks;
6. Q : What does CSAS_STOCKS_0 query ? A : transform CSV -> AVRO
7. Q : select 4 records from stocks_predictions stream.    A : select * from stocks_predictions limit 4;

```ksql> exit```

Q : Read raw data from topic predictions. 
A  docker run -it --network=kafka_default edenhill/kafkacat:1.5.0 -C -c2 -b broker:29092 -t predictions -J

### Spark

``` 
cd spark/streamapp && ./start.sh 
open  http://localhost:8080/     check application is running
``` 

Q. Open KafkaStream.scala. Explain function from_confluent_avro(..)
Open docker-compose.yml and check how to load integration kafka with structured spark streams
 --packages za.co.absa:abris_2.11:3.0.3
 --repositories http://packages.confluent.io/maven/

Q. Line 60 :  How do we call the predictor API ? Limitations ? 
A. Use mapPartitions function

Q. Line 76 : spark.sql("select * from predictions").select(to_json(struct($"*")).alias("value"))
A: Pack columns to json struct and assign it to value part of kafka message

### ELK

Q. How to read first 10 records from ELK ? A. http://localhost:9200/market/_search?pretty

Q. How to check status KAFKA-ELK sink connector ? A. http://localhost:9200/elk/status

### Grafana
```
open http://localhost:3000  admin/admin -> skip
```

Configure ELK data source and dashboard :
add data source -> name=ELK; type=ElasticSearch; URL=http://elasticsearch:9200
index name=market; Time field name=DT

Create dashboard :  Graph -> Last 5  years -> Refreshing query=5s
1. Query 1 : TICKER=AAPL, Metric=Max; CLOSED
2. Query 2 : TICKER=AAPL_P, Metric=Max; CLOSED

### Stop all

```
cd prophet && ./stop.sh
cd spark/streamapp && ./stop.sh
cd kafka && ./stop.sh
```

