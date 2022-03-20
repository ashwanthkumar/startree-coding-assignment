#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${SCRIPT_DIR}/bin/functions.sh

## We're going to assume: helm and kubectl is already installed, configured and is available on PATH.

op=$1

case $op in
  "start-local")
    start_local
  ;;

  "stop-local")
    stop_local
  ;;

  "install")
    install
  ;;

  # TODO: Use the ingress from file API where we can upload the file
  "load-data")
    kubectl port-forward service/pinot-controller 9000:9000 -n pinot &
    CONTROLLER_PORT_FORWARD_PID=$!
    log "waiting for a few seconds for the kubectl port-forward to start"
    sleep 5

    # Create Schema
    log "Creating Schema"
    curl -X POST "http://localhost:9000/schemas?override=true" -H "accept: application/json" -H "Content-Type: application/json" -d @sample-data/greenhouseGazEmission-schema.json
    log "Schema created"
    # Create Table
    log "Creating Table"
    curl -X POST "http://localhost:9000/tables" -H "accept: application/json" -H "Content-Type: application/json" -d @sample-data/greenhouseGazEmission-config.json
    log "Table Created"

    log "Loading data into table"
    # Load data into Table
    INPUT_FORMAT="csv"
    RECORD_DELIMITER=","
    batchConfigMapStr=$(printf %s "{   \"inputFormat\":\"${INPUT_FORMAT}\",   \"recordReader.prop.delimiter\":\"${RECORD_DELIMITER}\" }" | jq -sRr @uri)
    curl -X POST -F file=@sample-data/env_ac_ainah_r2.csv -H "Content-Type: multipart/form-data" "http://localhost:9000/ingestFromFile?tableNameWithType=greenhouseGazEmission_OFFLINE&batchConfigMapStr=${batchConfigMapStr}"
    log "Data loaded into table"

    kill ${CONTROLLER_PORT_FORWARD_PID}
  ;;

  "remove-data")
    kubectl port-forward service/pinot-controller 9000:9000 -n pinot --pod-running-timeout=1m0s &
    CONTROLLER_PORT_FORWARD_PID=$!

    echo "waiting for a few seconds for the kubectl port-forward to start"
    sleep 5

    # Remove Table
    curl -X DELETE "http://localhost:9000/tables/greenhouseGazEmission?type=OFFLINE" -H "accept: application/json"
    # Remove Schema
    curl -X DELETE "http://localhost:9000/schemas/greenhouseGazEmission" -H "accept: application/json"

    kill ${CONTROLLER_PORT_FORWARD_PID}
  ;;

  "remove")
    remove
  ;;

  "trigger-load")
    for i in {1..100000};
    do
      curl 'http://localhost:9000/sql' --data-raw '{"sql":"select * from greenhouseGazEmission limit 1","trace":false}' > /dev/null
    done
  ;;

  *)
    me=`basename "$0"`
    echo "Invalid Usage."
    echo "Try ./$me install or ./$me remove"
  ;;

esac
