#!/bin/bash
#!/bin/bash
OS="$(grep ^NAME= /etc/os-release |tr \"[:upper:]\" \"[:lower:]\")"
[[ $OS =~ "red hat enterprise linux" || $OS =~ "centos" || $OS =~ "rocky" || $OS =~ "alma" ]] && yum -y install epel-release && yum -y install curl jq
[[ $OS =~ "debian" || $OS =~ "ubuntu" ]] && apt-get update && apt-get -y install curl jq


META_ANSIBLE="$(curl -s http://169.254.169.254/openstack/2018-08-27/meta_data.json | jq '.meta._ANSIBLE_URL_' | tr -d '"')"
META_SHARE="$(curl -s http://169.254.169.254/openstack/2018-08-27/meta_data.json | jq '.meta._SHARE_' | tr -d '"')"

ANSIBLE=false
NFS=false

if [ -n "$META_ANSIBLE" ]; then
    _ANSIBLE_URL_="$META_ANSIBLE"
    ANSIBLE=true
fi
if [ -n "$META_SHARE" ]; then
    _SHARE_="$META_SHARE"
    NFS=true
fi

if $NFS ; then
    mount "${_SHARE_}" /mnt
fi
if $ANSIBLE ;then
    [[ $OS =~ "red hat enterprise linux" || $OS =~ "centos" || $OS =~ "rocky" || $OS =~ "alma" ]] && yum -y install epel-release && yum -y install ansible
    [[ $OS =~ "debian" || $OS =~ "ubuntu" ]] && apt-get update && apt-get -y install ansible
    curl -s -L --connect-timeout 60 -o /tmp/my_playbook.yaml "${_ANSIBLE_URL_}"
    ansible-playbook /tmp/my_playbook.yaml
fi

curl https://gist.githubusercontent.com/MattIPv4/045239bc27b16b2bcf7a3a9a4648c08a/raw/2411e31293a35f3e565f61e7490a806d4720ea7e/bee%2520movie%2520script > /root/beemovie.txt