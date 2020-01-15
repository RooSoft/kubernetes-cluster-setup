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

setupFirewall() {
 firewall="\
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<service>
  <short>kubernetes</short>
  <description>kubernetes</description>
  <port protocol=\"tcp\" port=\"8472\"/>
  <port protocol=\"tcp\" port=\"10250\"/>
  <port protocol=\"tcp\" port=\"10255\"/>
  <port protocol=\"tcp\" port=\"30000-32767\"/>
</service>"

  printf "$firewall" > /etc/firewalld/services/kubernetes.xml

  systemctl restart network.service
  systemctl restart firewalld.service
  firewall-cmd --zone=public --add-service=kubernetes
  firewall-cmd --zone=public --add-service=kubernetes --permanent
}

setupFirewall

echo You can now issue the kubernetes join command
