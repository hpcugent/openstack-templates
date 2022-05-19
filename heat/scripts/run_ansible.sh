#!/bin/bash
OS="$(grep ^NAME= /etc/os-release |tr \"[:upper:]\" \"[:lower:]\")"
[[ $OS =~ "red hat enterprise linux" || $OS =~ "centos" || $OS =~ "rocky" || $OS =~ "alma" ]] && yum -y install epel-release && yum -y install ansible curl
[[ $OS =~ "debian" || $OS =~ "ubuntu" ]] && apt-get update && apt-get -y install ansible curl
curl -L --connect-timeout 60 -o /tmp/my_playbook.yaml "__ANSIBLE_URL__"
ansible-playbook /tmp/my_playbook.yaml
retcode=$?
if [ $retcode -eq 0 ]
then
	wc_notify --data-binary "{\"status\": \"SUCCESS\", \"reason\": \"Ansible playbook successful.\"}" 
else
        wc_notify --data-binary "{\"status\": \"FAILURE\", \"reason\": \"Ansible playbook not successful.\"}"
fi
