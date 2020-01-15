#! /bin/bash

# declare environment variables if unset
[ -z $PUBLIC_IP ] && PUBLIC_IP=192.168.13.90
[ -z $POD_NETWORK_CIDR ] && POD_NETWORK_CIDR=192.168.14.0/24
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

setupFirewall() {
  firewall="\
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<service>
  <short>kubernetes</short>
  <description>kubernetes</description>
  <port protocol=\"tcp\" port=\"6443\"/>
  <port protocol=\"tcp\" port=\"2379-2380\"/>
  <port protocol=\"tcp\" port=\"10250\"/>
  <port protocol=\"tcp\" port=\"10251\"/>
  <port protocol=\"tcp\" port=\"10252\"/>
  <port protocol=\"tcp\" port=\"10255\"/>
  <port protocol=\"udp\" port=\"8472\"/>
</service>
"

  printf "$firewall" > /etc/firewalld/services/kubernetes.xml

  systemctl restart network.service
  systemctl restart firewalld.service
  firewall-cmd --zone=public --add-service=kubernetes
  firewall-cmd --zone=public --add-service=kubernetes --permanent
}

setupFirewall

# init kubernetes controle-plane
kubeadm init --apiserver-advertise-address=$PUBLIC_IP --pod-network-cidr=$POD_NETWORK_CIDR

