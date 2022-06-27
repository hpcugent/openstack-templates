#!/bin/bash
OS="$(grep ^NAME= /etc/os-release |tr \"[:upper:]\" \"[:lower:]\")"
[[ $OS =~ "red hat enterprise linux" || $OS =~ "centos" || $OS =~ "rocky" || $OS =~ "alma" ]] && yum -y install epel-release && yum -y install ansible curl
[[ $OS =~ "debian" || $OS =~ "ubuntu" ]] && apt-get update && apt-get -y install ansible curl
curl -L --connect-timeout 60 -o /tmp/my_playbook.yaml "${_ANSIBLE_URL_}"
ansible-playbook /tmp/my_playbook.yaml
