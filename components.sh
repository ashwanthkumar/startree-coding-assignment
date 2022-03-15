#!/bin/bash

set -e

## We're going to assume: helm and kubectl is already installed, configured and is available on PATH.

op=$1

function log {
  msg=$1
  echo "$(date): $msg" >&2
}

case $op in
  "install")
    ## Install Pinot

    log "Installing Pinot via Helm with timeout of 150s"
    ## This should help create NS if not exist else it would not do anything we can safely run this multiple times
    kubectl create ns pinot --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait --timeout 150s pinot pinot/pinot -n pinot --values helm-pinot-values.yaml

    log "Installing Prometheus via Helm with timeout of 100s"
    ## Install Prometheus
    kubectl create ns prometheus --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait --timeout 100s prometheus prometheus-community/prometheus -n prometheus --values helm-prometheus-values.yaml

    log "Installing Grafana via Helm with timeout of 60s"
    ## Install Grafana (Optional)
    kubectl create ns grafana --dry-run=client -o yaml | kubectl apply --filename -
    helm install --wait --timeout 60s grafana grafana/grafana -n grafana --values helm-grafana-values.yaml

    log "Installing Prometheus-Adapter via Helm with timeout of 100s"
    ## Install Prometheus Adaptor
    helm install --wait --timeout 100s prometheus-adapter prometheus-community/prometheus-adapter -n prometheus --values helm-prometheus-adapter.yaml
  ;;

  "remove")
    # Remove Pinot
    helm uninstall --wait pinot -n pinot
    # Remove prometheus-adapter
    helm uninstall --wait prometheus-adapter -n prometheus
    # Remove Grafana
    helm uninstall --wait grafana -n grafana
    # Remove Prometheus
    helm uninstall --wait prometheus -n prometheus
  ;;

  *)
    me=`basename "$0"`
    echo "Invalid Usage."
    echo "Try ./$me install or ./$me remove"
  ;;

esac
