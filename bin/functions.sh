#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

function log {
  msg=$1
  echo "$(date): $msg" >&2
}

function start_local {
  minikube  start  --memory='max' --wait='all'
}

function install {
    helm repo add pinot https://raw.githubusercontent.com/apache/pinot/master/kubernetes/helm
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    ## Install Pinot
    log "Installing Pinot via Helm with timeout of 10m"
    ## This should help create NS if not exist else it would not do anything we can safely run this multiple times
    kubectl create ns pinot --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait --timeout 10m pinot pinot/pinot -n pinot --values helm-pinot-values.yaml

    log "Installing Prometheus via Helm"
    ## Install Prometheus
    kubectl create ns prometheus --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait prometheus prometheus-community/prometheus -n prometheus --values helm-prometheus-values.yaml

    log "Installing Grafana via Helm"
    ## Install Grafana (Optional)
    kubectl create ns grafana --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait grafana grafana/grafana -n grafana --values helm-grafana-values.yaml

    log "Installing Prometheus-Adapter via Helm"
    ## Install Prometheus Adaptor
    helm install --wait prometheus-adapter prometheus-community/prometheus-adapter -n prometheus --values helm-prometheus-adapter.yaml

    log "Installing the Pinot HPA"
    kubectl apply -f pinot-hpa-spec.yaml -n pinot
}

function stop_local {
  minikube stop
}

function load_data {
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
}

function trigger_load {
  kubectl port-forward service/pinot-controller 9000:9000 -n pinot &
  CONTROLLER_PORT_FORWARD_PID=$!
  log "waiting for a few seconds for the kubectl port-forward to start"
  sleep 5

  MAX_COUNT=15000
  log "Starting load on the server. Running ${MAX_COUNT} queries"
  for i in `seq 1 ${MAX_COUNT}`;
  do
    if (( $i % 1000 == 0))
    then
      log "Made $i requests so far out of ${MAX_COUNT}"
    fi
    curl --silent 'http://localhost:9000/sql' --data-raw '{"sql":"select * from greenhouseGazEmission limit 1","trace":false}' > /dev/null
  done

  kill ${CONTROLLER_PORT_FORWARD_PID}
}