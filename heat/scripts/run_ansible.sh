#!/bin/bash
OS="$(cat /etc/os-release |grep ^NAME=|tr [:upper:] [:lower:])"
[[ $OS =~ "fedora" || $OS =~ "red hat enterprise linux" || $OS =~ "centos" || $OS =~ "rocky" || $OS =~ "alma" ]] && yum -y install epel-release && yum -y install ansible curl
[[ $OS =~ "debian" || $OS =~ "ubuntu" ]] && apt-get update && apt-get -y install ansible curl
curl -L --connect-timeout 60 -o /tmp/my_playbook.yaml "__ANSIBLE_URL__"
ansible-playbook /tmp/my_playbook.yaml
[ $? -eq 0 ] && wc_notify --data-binary "{\"status\": \"SUCCESS\", \"reason\": \"Ansible playbook successful.\"}" || wc_notify --data-binary "{\"status\": \"FAILURE\", \"reason\": \"Ansible playbook not successful.\"}"
