#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${SCRIPT_DIR}/bin/functions.sh

## We're going to assume: helm and kubectl is already installed, configured and is available on PATH.

op=$1

case $op in
  "demo-auto-scale")
    start_local
    install
    load_data
    trigger_load

    ## Now that we're done with the load, the idea is that the number of brokers in the cluster should have scaled up.
    EXPECTED_REPLICAS=2
    CURRENT_REPLICAS=$(kubectl get hpa -n pinot pinot-broker  -o json | jq -r .status.currentReplicas)
    if (( ${CURRENT_REPLICAS} == ${EXPECTED_REPLICAS} ))
    then
      log "We've successfully verified that the number of brokers have scaled up"
    else
      log "Oops, the current replicas for the HPA is $CURRENT_REPLICAS, while it should be ${EXPECTED_REPLICAS}"
    fi
  ;;

  "start-local")
    start_local
  ;;

  "stop-local")
    stop_local
  ;;

  "install")
    install
  ;;

  "load-data")
    load_data
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

  "trigger-load")
    trigger_load
  ;;

  *)
    me=`basename "$0"`
    echo "Invalid Usage."
    echo "Try ./$me demo-auto-scale"
  ;;

esac
