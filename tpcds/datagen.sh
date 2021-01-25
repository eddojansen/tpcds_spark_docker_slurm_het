#!/bin/bash

set -x

/opt/spark/bin/spark-shell -I ${TPCDS_HOME}/tpcds_datagen.scala --master spark://${MASTER}:7077 --jars ${SPARK_SQL_JAR} --executor-memory ${EXECUTOR_MEMORY}
