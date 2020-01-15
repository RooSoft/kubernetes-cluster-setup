#! /bin/bash

# issue commands with arguments to stdout
set -x

# ensure NOT root
if [[ $UID -eq 0 ]] ; then
  echo "Must not be root" >&2
  exit 1
fi

# setup ~/.kube/config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# setup weaves
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

