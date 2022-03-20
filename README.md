# startree-coding-assignment

Refer to [PROBLEM.md](./PROBLEM.md) for the problem statement.

## Requirements

- [minikube](https://minikube.sigs.k8s.io/docs/start/): After installing, run `minikube start`. The Usage section assumes you can run `minikube kubectl -- get pods -A` successfully. 
- Run `alias kubectl="minikube kubectl --"` to point `kubectl` to one from `minikube`.
- [helm](https://helm.sh/docs/intro/install/): After installing, run `helm version` and it should print the version of helm which should be v3.8+.
- [jq](https://stedolan.github.io/jq/)

## Changes to the helm values
### Pinot
- Disabled ExternalIP since we're running locally and can't have external ip assigned, this also blocks `helm install --wait` from detecting the full installation.

### Grafana
- Setting the admin password as `admin`. So we can login using admin/admin on the UI.

### Prometheus Adapter
- Configure the Prometheus URL against our installation

## Usage

```
# To install Pinot, Prometheus, Grafana, Prometheus-Adapter to our k8s
$ ./components.sh demo-auto-scale

# To remove the above installed components after testing run this to claim the system resources
$ ./components.sh remove
```

