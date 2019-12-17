package com.example.acme.streamApp

import org.apache.spark.{ SparkConf, SparkContext }
import org.apache.spark.sql.SparkSession
import org.apache.spark.streaming._
import org.apache.spark.streaming.kafka010._
import za.co.absa.abris.avro.read.confluent.SchemaManager
import za.co.absa.abris.avro.functions.from_confluent_avro
import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import java.time.LocalDate
import java.time.format._
import requests._
import ujson._

// === Model ====

case class Quote(dt: String, ticker: String, var closed: Double)
object Quote {
  def apply(r: Row): Quote = Quote(r.getAs[String]('DT.name), r.getAs[String]('TICKER.name), r.getAs[Double]('CLOSED.name))
}

//  end Model ===

object KafkaStreamApp {

  def main(args: Array[String]) {
    if (args.length < 5) {
      System.err.println(s"""Usage: KafkaStreamApp <brokers> <groupId> <topic_quotes> <topic_predictions> <url_predictor>
        |  <brokers> is a list of one or more Kafka brokers
        |  <groupId> is a consumer group name to consume from topics (optional)
        |  <topic_quotes> is a topics to consume from
        |  <topic_predictions> is topic to produce predicted quote
        |  <url_predictor> url to predictor service
        """.stripMargin)
      System.exit(1)
    }

    val Array(brokers, groupId, topic_quotes, topic_predictions, url_predictor) = args

    val spark = SparkSession.builder.appName("WorkshopStreamApp").getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")

    import spark.implicits._

    val df = spark.readStream
      .format("kafka")
      .option("kafka.bootstrap.servers", brokers)
      .option("subscribe", topic_quotes)
      .option("startingOffsets", "earliest")
      .load()

    val schemaRegistryConfig = Map(
      SchemaManager.PARAM_SCHEMA_REGISTRY_URL -> "http://schema-registry:8081",
      SchemaManager.PARAM_SCHEMA_REGISTRY_TOPIC -> topic_quotes,
      SchemaManager.PARAM_VALUE_SCHEMA_NAMING_STRATEGY -> SchemaManager.SchemaStorageNamingStrategies.TOPIC_NAME,
      SchemaManager.PARAM_VALUE_SCHEMA_ID -> "latest")

    val data = df.select(from_confluent_avro(col("value"), schemaRegistryConfig) as 'data).select("data.*")

    //  TASK 2 : == YOUR SOLUTION IS HERE ==
    //
    //   Start kafka if required and ksql shell
    //   $ cd kafka && ./start.sql && ./ksql-run.sh
    //   Start prophet predictor
    //   $ cd prophet && ./start.sh
    // 
    //   For each row in data collection
    //     
    //   Construct URL request and call Prophet predictor 
    //   Assign nextDayQuote.closed = <parse Json response and get CLOSED field>
    //   Use pattern matching like : 
    //      
    //      val response = requests.get <next date>
    //      nextDayQuote.closed = response.statusCode match {
    //        case 200 => <use ujson library to  parse  response and extract CLOSED value>
    //        case _   => 0.0 
    //      }
    //
    //      Open second terminal and start producer : cd kafka && ./send-file.sh
    //      ksql> print 'predictions';   # start listen to target topic
    //      Launch spark cluster :  $ ./start.sh  (after ./send-file.sh)
    //      you should see Executor updated: app-XXXXX is now RUNNING
    //       
    //      In ksql shell you shoul see ksql> Format:JSON
    //        {"ROWTIME":1576191021292,"ROWKEY":"null","dt":"2014-10-11","ticker":"AAPL","closed":0.0}
    //        {"ROWTIME":1576191021468,"ROWKEY":"null","dt":"2014-10-14","ticker":"AAPL","closed":115.47127407369688}
    //        ....
    //
    //      Congratulations ! You finished Task 2. Here you integrated  kafka, spark and prophet. 
    //
    //      Go to Task 3 : cd ./prophet/apps/flask-app.py
    //

    val predictions = data map (row => {

      val quote = Quote(row)
      val nextDayQuote = nextDay(quote)

      //   == YOUR SOLUTION IS HERE ==



      // == END YOUR SOLUTION IS HERE ==

      nextDayQuote
    })

    predictions.createOrReplaceTempView("predictions")

    // Workshop :  Can you explain this one ?
    val result = spark.sql("select * from predictions")
      .select(to_json(struct($"*"))
        .alias("value"))

    //  write to kafka topic
    val stream = result.writeStream.format("kafka")
      .outputMode("append")
      .option("kafka.bootstrap.servers", brokers)
      .option("checkpointLocation", "./checkpoint")
      .option("topic", topic_predictions)
      .start()
      .awaitTermination()

    // Use console to debug
    /*
    val stream = data
          .writeStream
          .format("console")
          .option("truncate", "false")
          .start()
          .awaitTermination()
    */
  }

  def nextDay(q: Quote): Quote = {
    val formatter = new DateTimeFormatterBuilder()
      .appendPattern("yyyy-MM-dd")
      .toFormatter();

    val dt = LocalDate.parse(q.dt, formatter);
    val nextDay = LocalDate.from(dt).plusDays(1)
    q.copy(dt = nextDay.toString())
  }
}