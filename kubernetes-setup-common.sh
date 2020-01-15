#! /bin/bash

# declare environment variables if unset
[ -z $DOCKER_VERSION ] && DOCKER_VERSION=18.09.1

# issue commands with arguments to stdout
set -x

# fail fast
trap 'displayError' ERR

displayError() {
  echo 'An error occured, stopping execution here...' >&2
  exit 1
}

# ensure root
if [[ $UID -ne 0 ]] ; then
  echo "Must be root" >&2
  exit 1
fi


testSwap() {
  if [[ $(swapon -s | wc -l) -gt 0 ]] ; then
    echo Please disable swap before running this
    exit 1
  fi
}

installDocker() {
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION} containerd.io
  systemctl start docker
  systemctl enable docker

  # fix docker version to avoid unwanted upgrades with yum
  yum install yum-plugin-versionlock -y
  yum versionlock docker-*
}

configureKubernetesRepo() {
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
}

configureSELinux() {
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
}

configureBridge() {
  cat <<EOF >  /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

  sysctl --system
}


testSwap
installDocker
configureKubernetesRepo

# install vim wget curl kubelet kubeadm and kubectl
yum install -y vim wget curl kubelet kubeadm kubectl --disableexcludes=kubernetes

# ensure kubelet will run at startup
systemctl enable --now kubelet

configureSELinux
configureBridge

