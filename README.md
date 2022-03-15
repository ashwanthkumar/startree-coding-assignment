# startree-coding-assignment

Refer to [PROBLEM.md](./PROBLEM.md) for the problem statement.

This solution is designed against `minikube` running locally on a Mac. If you already don't have minikube setup locally, please refer to https://minikube.sigs.k8s.io/docs/start/ to download and install the right version of the binary on your machine. After which you need to run `minikube start`. The Usage section assumes you can run `minikube kubectl -- get pods -A` successfully. You also need to make sure `helm` is installed and is available on PATH, please refer to https://helm.sh/docs/intro/install/ for installation instructions for Helm.

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
$ ./components.sh install

# To remove the above installed components after testing run this to claim the system resources
$ ./components.sh remove
```

