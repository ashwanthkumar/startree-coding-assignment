# startree-coding-assignment

Refer to [PROBLEM.md](./PROBLEM.md) for the problem statement.

This solution is designed against `minikube` running locally on a Mac. If you already don't have minikube setup locally, please refer to https://minikube.sigs.k8s.io/docs/start/ to download and install the right version of the binary on your machine. After which you need to run `minikube start`. The Usage section assumes you can run `minikube kubectl -- get pods -A` successfully. You also need to make sure `helm` is installed and is available on PATH, please refer to https://helm.sh/docs/intro/install/ for installation instructions for Helm.

## Usage

```
# To get started, we first have to install the necessary components into our cluster
$ ./tools.sh install

# After testing things out you can run the following to remove all the components that we installed locally
$ ./tools.sh remove
```

