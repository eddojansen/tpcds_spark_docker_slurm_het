 python /data/tpcds/benchmark.py \
  --template ${TPCDS_HOME}/spark-submit-template.txt \
  --input ${INPUT_PATH} \
  --input-format ${INPUT_FORMAT} \
  --output ${OUTPUT_PATH}\
  --output-format ${OUTPUT_FORMAT} \
  --configs ${TPCDS_HOME}/tpcds-config \
  --benchmark ${BENCHMARK} \
  --iterations ${ITERATIONS} \
  --query ${QUERY}
