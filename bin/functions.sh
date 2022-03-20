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
}

function remove {
    # Remove Pinot
    helm uninstall --wait pinot -n pinot
    # Remove prometheus-adapter
    helm uninstall --wait prometheus-adapter -n prometheus
    # Remove Grafana
    helm uninstall --wait grafana -n grafana
    # Remove Prometheus
    helm uninstall --wait prometheus -n prometheus
}

function stop_local {
  minikube stop
}