package com.example.acme.streamapp

import org.scalatest._
import java.time.LocalDate
import java.time.format._

class QuoteSpec extends FlatSpec {

  it should "return next date" in {
    val formatter = new DateTimeFormatterBuilder()
      .appendPattern("yyyy-MM-dd")
      .toFormatter();

    val dt = LocalDate.parse("2017-11-30", formatter);
    val nextDay = LocalDate.from(dt).plusDays(1)
    
    assert("2017-12-01" === nextDay.toString())
  }

}

