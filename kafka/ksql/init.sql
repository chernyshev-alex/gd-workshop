-- set 'commit.interval.ms'='2000';
-- set 'cache.max.bytes.buffering'='10000000';
-- set 'auto.offset.reset'='earliest';

-- Pipeline design : ------
--
-- 1. [csv-producer] -> topic:stock_csv -> stream:stocks -> ELK connect:elastic -> graphana
-- 2. stream:stocks -> spark:stream-app -> propheat:predict  -> topic:predictions -> topic:stocks_predictions
-- 3. topic:stocks_predictions -> ELK connect:elastic  -> graphana
----------

--  This stream reads from input CSV topic : stocks-csv

CREATE STREAM stocks_csv(DT STRING, OPENED DOUBLE, HIHG DOUBLE, LOW DOUBLE, CLOSED DOUBLE, ADJ_CLOSED DOUBLE, VOLUME BIGINT) 
     WITH (kafka_topic='stocks-csv', value_format='DELIMITED');

--  This stream converts CSV data from stocks_csv stream & writes to topic 'stocks' in AVRO format 
--  ELK connector puts data to elastic search from this topic

CREATE STREAM stocks WITH (kafka_topic='stocks', VALUE_FORMAT='avro', timestamp='DT', timestamp_format='yyy-MM-dd') AS
     SELECT DT, 'AAPL' AS TICKER, CLOSED FROM stocks_csv PARTITION BY TICKER;

CREATE STREAM predictions(DT STRING, TICKER STRING, CLOSED DOUBLE) 
     WITH (kafka_topic='predictions', VALUE_FORMAT='json', timestamp='DT', timestamp_format='yyy-MM-dd');
 
-- TASK 1 : KSQL --
--
--  Introduction : 
--
--  Spark streaming application, writes predicted quotes to the topic 'predictions' in JSON format.
--  We use ELK connector to deliver quotes to the elastic search cluster.
--  ELK connector consumes records from topics in avro format only.
--  
--  What should be done :
--  
--  Create kafka STREAM 'stocks_predictions' that reads json quotes from the topic 'predictions' and writes them down
--  to the topic 'stocks-predictions' in avro format.
-- 
--  input (predictions, json) : { DT : STRING, TICKER : STRING, CLOSED : DOUBLE }
--  output (stocks_predictions, avro) :  { DT : STRING, TICKER : STRING, CLOSED : DOUBLE }
--       add to output TICKER suffix '_P' and filter out quotes with CLOSED > 0.0
--       records should be  partitioned by DT
--       kafka system field timestamp='DT' and timestamp_format='yyy-MM-dd'
--  
--  Example :  
--    input :  DT=2019-10-03, TICKER='AAPL', 122.99
--    output : DT=2019-10-04, TICKER='AAPL_P', 123.22

--  Implementation notes : 
--  
--  Study cookbook how to convert data in stream from json to avro
--  https://www.confluent.io/stream-processing-cookbook/
--
--  1. $ cd kafka && ./start.sh 
--     start two ksql shells : $ ./ksql-run.sh  
--     then in the new termial type again $> ./ksql-run.sh 
--     Use one ksql shell (ksql1>) to develop strem SQL and other (ksql2>) for debug
-- 
--  3. develop your solution
--     
--     Use ksql(1) to develop your code :
--     ksql(1)> DROP/CREATE STREAM stocks_predictions ....
--     Check the created stream 'stocks_predictions' has properties 
--     kafka_topic='stocks-predictions', VALUE_FORMAT='avro',  timestamp='DT', timestamp_format='yyy-MM-dd'

--     ksql(1)> print 'predictions';   # start listen to topic
-- 
--     Use ksql(2) to send data to the topic 'predictions' to test your stream : 
--       ksql(2)> INSERT INTO PREDICTIONS(DT, TICKER, CLOSED) VALUES('2019-10-02', 'AAPL', 100.01);
--     Yu should see this :
--       ksql(1)> Format:JSON
--         {"ROWTIME":1576185462179,"ROWKEY":"null","DT":"2019-10-02","TICKER":"AAPL","CLOSED":100.01}
--
--       ** This is test to make sure that you implemented solution correctly **
--       ksql(2)> print 'stocks-predictions';  # listen to target topic
--       ksql(2)> INSERT INTO PREDICTIONS(DT, TICKER, CLOSED) VALUES('2019-10-02', 'AAPL', 100.01);
--       ksql(1)> Format:AVRO
--        10/2/19 12:00:00 AM UTC, AAPL_P, {"DT": "2019-10-02", "TICKER": "AAPL_P", "CLOSED": 100.01}
--       
--      Pay the attention, when your inserted data to the stream PREDICTIONS, you got data in correct AVRO format
--         from topic 'stocks-predictions'. 
--      So, you created stream and long running SQL correctly.
--
--      Notes : to drop stream use 
--        ksql> terminate <query>; drop stream STOCKS_PREDICTIONS;
--     
--  5. check that ELK connector transmited inserted data to Elastic search 
--      $ curl localhost:9200/market/_search?pretty   
--  6. add your code to init.sql script instead of placeholder == YOUR SOLUTION IS HERE ==
--      and restart kafka server $ ./stop.sh  $ ./start.sh
--
--     You finished KSQL task and time to go to the spark streaming task !!
--
-- == YOUR SOLUTION IS HERE ==
-- Here is example of one possible soluton
-- !!! Remove this before start workshop !!!
