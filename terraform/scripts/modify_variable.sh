#!/bin/bash

Help() {
    echo
    echo "options:"
    echo "-h     Print this Help."
    echo "-k     (optional) updates TF variables but it keeps same portforwarding ports"
    echo
}

KEEP_PF_PORTS="false"

while getopts ":hk" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      k) # Keep ports
         KEEP_PF_PORTS="true";;
     \?) # Invalid option
         echo "Error: Invalid option"
         Help
         exit;;
   esac
done

source modify_variable.config &>/dev/null
[ -z ${IMAGE_NAME+x} ] && echo "Variable IMAGE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${FLAVOR_NAME+x} ] && echo "Variable FLAVOR_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${SHARE_NAME+x} ] && echo "Variable SHARE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${SHARE_SIZE+x} ] && echo "Variable SHARE_SIZE is not set. Exiting.." 1>&2 && exit 1
[ -z ${VM_BASE_NAME+x} ] && echo "Variable VM_BASE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${vm_floating_ip_cidr+x} ] && echo "Variable vm_floating_ip_cidr is not set. Exiting.." 1>&2 && exit 1
[ -z ${vsc_floating_ip_cidr+x} ] && echo "Variable vsc_floating_ip_cidr is not set. Exiting.." 1>&2 && exit 1

[ -z ${OS_CLOUD+x} ] && echo "Variable OS_CLOUD is not set. Using openstack as a value." && export OS_CLOUD=openstack

if ! eval openstack catalog list &>/dev/null; then
  echo "Unable to list openstack catalog. Exiting.." 1>&2
  exit 1
fi

if ! eval openstack image show "$IMAGE_NAME" &>/dev/null; then
  echo "Unable to locate image $IMAGE_NAME. Exiting.." 1>&2
  exit 1
fi

image_id="$(openstack image show "$IMAGE_NAME" -c id -f value)"
	echo "Image id: $image_id. (Image name: $IMAGE_NAME)"
	echo "Flavor name: $FLAVOR_NAME."
image_windows_id="$(openstack image show "$IMAGE_WINDOWS_NAME" -c id -f value)"
	echo "Image id: $image_windows_id. (Image name: $IMAGE_WINDOWS_NAME)"
	echo "Flavor name: $FLAVOR_NAME."
root_fs_volume_size=$(openstack flavor show "${FLAVOR_NAME}" -f value -c disk)
	echo "Root FS volume size based on flavor disk size: $root_fs_volume_size."
vm_network_id="$(openstack network list -f value -c ID -c Name|grep '_vm'|cut -d ' ' -f1)" && \
	echo "VM network id: $vm_network_id."
vm_subnet_id="$(openstack network list -c Subnets -c Name|grep '_vm'|awk '{print $4}')" && \
	echo "VM subnet id: $vm_subnet_id."
nfs_network_id="$(openstack network list -f value -c ID -c Name|grep '_nfs'|cut -d ' ' -f1)" && \
	echo "NFS network id: $nfs_network_id."
nfs_subnet_id="$(openstack network list -c Subnets -c Name|grep '_nfs'|awk '{print $4}')" && \
	echo "NFS subnet id: $nfs_subnet_id."
vsc_network_id="$(openstack network list -f value -c ID -c Name|grep '_vsc'|cut -d ' ' -f1)" && \
	echo "VSC network id: $vsc_network_id."
vsc_subnet_id="$(openstack network list -c Subnets -c Name|grep '_vsc'|awk '{print $4}')" && \
	echo "VSC subnet id: $vsc_subnet_id."
windows_admin_password="$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 16 | tr -d '\n')"

access_key="$(openstack keypair list -c Name -f value|head -1)"
[ -z "$access_key" ] && echo "Unable to find ssh access key. Exiting.." 1>&2 && exit 1
echo "Using first ssh access key \"$access_key\"."

while read -r line
do
	ip="$(echo "$line"|awk '{print $2}')"
	ip_id="$(echo "$line"|awk '{print $1}')"
	python3 -c "import ipaddress; ip = ipaddress.ip_address('$(echo "$ip")') in ipaddress.ip_network('$(echo "$vm_floating_ip_cidr")'); \
		print (ip);"|grep "True" &>/dev/null && export floating_ip_id="$ip_id" && export floating_ip="$ip" && \
		break
done < <(openstack floating ip list -f value -c "Floating IP Address" -c ID -c "Port"|grep None)
[ -z "$floating_ip_id" ] && echo "Unable to find floating ip address. Exiting.." 1>&2 && exit 1
echo "Using floating ip id: $floating_ip_id. (floating ip: $floating_ip)"
while read -r line
do
        ip="$(echo "$line"|awk '{print $1}')"
	python3 -c "import ipaddress; ip = ipaddress.ip_address('$(echo "$ip")') in ipaddress.ip_network('$(echo "$vsc_floating_ip_cidr")'); \
		print (ip);"|grep "True" &>/dev/null && export vsc_floating_ip="$ip" && \
		break
done < <(openstack floating ip list -f value -c "Floating IP Address" -c "Port"|grep None)
[ -z "$vsc_floating_ip" ] && echo "VSC floating ip address not present."
echo "Using VSC floating ip: $vsc_floating_ip."

generate_new_free_port () {
  column="External Port"
  allocated_ports=$(openstack floating ip port forwarding list "$floating_ip_id" -f value -c "$column" --sort-column "$column")
  for i in $(seq 100); do
    port="$(shuf -i 51001-59999 -n 1)"
    if [[ ! " $allocated_ports " =~ " $port " ]]; then
      new_port="$port"
      break
    fi
  done
}


echo "Modifying ../environment/main.tf file."

# main.tf is overrided and new external ports are generated each run
yes| cp -rf ../environment/main.tf.template ../environment/main.tf

verify_variable() {
        #usage: verify_variable "variable to check" "module to comment out if variable is empty"
        variable="$1"
        module_to_comment_out="$2"
        if [ "${!variable}" == "" ]
        then
                echo "WARNING: Missing \$$variable. Commenting out $module_to_comment_out module in ../environment/main.tf file."
                awk "/module.*$module_to_comment_out/,/}/{\$0=\"#\"\$0}1" ../environment/main.tf  > ../environment/main.tf_new
                mv ../environment/main.tf_new ../environment/main.tf
        fi
}

verify_variable "nfs_network_id" "vm_with_pf_rules_with_ssh_access_with_nfs_share"
verify_variable "vsc_network_id" "vm_with_pf_rules_with_ssh_access_with_vsc_net"

sed -i "s/_FLAVOR_NAME_/$FLAVOR_NAME/g" ../environment/main.tf
sed -i "s/_SHARE_NAME_/$SHARE_NAME/g" ../environment/main.tf
sed -i "s/_SHARE_SIZE_/$SHARE_SIZE/g" ../environment/main.tf
sed -i "s/_VM_BASE_NAME_/$VM_BASE_NAME/g" ../environment/main.tf
sed -i "s/_ROOT_FS_VOLUME_SIZE_/$root_fs_volume_size/g" ../environment/main.tf
sed -i "s/_IMAGE_ID_/$image_id/g" ../environment/main.tf
sed -i "s/_IMAGE_WINDOWS_ID_/$image_windows_id/g" ../environment/main.tf
sed -i "s/_VM_NETWORK_ID_/$vm_network_id/g" ../environment/main.tf
sed -i "s/_VM_SUBNET_ID_/$vm_subnet_id/g" ../environment/main.tf
sed -i "s/_NFS_NETWORK_ID_/$nfs_network_id/g" ../environment/main.tf
sed -i "s/_NFS_SUBNET_ID_/$nfs_subnet_id/g" ../environment/main.tf
sed -i "s/_VSC_NETWORK_ID_/$vsc_network_id/g" ../environment/main.tf
sed -i "s/_VSC_SUBNET_ID_/$vsc_subnet_id/g" ../environment/main.tf
sed -i "s/_ACCESS_KEY_/$access_key/g" ../environment/main.tf
sed -i "s/_WINDOWS_ADMIN_PASSWORD_/$windows_admin_password/g" ../environment/main.tf

if [[ "$KEEP_PF_PORTS" = 'false' ]]; then
  truncate -s 0 ../environment/used_ports.out
  for suffix in $(seq 1 5); do
    generate_new_free_port
    declare ssh_forwarded_port"$suffix"="$new_port"
  done
  generate_new_free_port && http_forwarded_port="$new_port"
else
  echo "keep-pf-ports enabled, keeping old port forwarding ports"
  grep ssh_forwarded_port ../environment/main.tf
  index=1
  while IFS= read -r line; do
    if [[ "$index" -eq 6 ]]; then
      declare http_forwarded_port="$line"
    else
      declare ssh_forwarded_port$index="$line"
    fi
    ((index++))
  done < ../environment/used_ports.out
fi

echo "Using ssh forwarded ports: $ssh_forwarded_port1 $ssh_forwarded_port2 $ssh_forwarded_port3 $ssh_forwarded_port4."
echo "Using http forwarded port: $http_forwarded_port."
echo "Using rdp forwarded port: $ssh_forwarded_port5."

for suffix in $(seq 1 5); do
  port=ssh_forwarded_port${suffix}
  sed -i "s/_SSH_FORWARDED_PORT${suffix}_/${!port}/g" ../environment/main.tf
  echo "${!port}" >> ../environment/used_ports.out
done
sed -i "s/_HTTP_FORWARDED_PORT_/$http_forwarded_port/g" ../environment/main.tf
echo "$http_forwarded_port" >> ../environment/used_ports.out

sed -i "s/_FLOATING_IP_ID_/$floating_ip_id/g" ../environment/main.tf
sed -i "s/_VSC_FLOATING_IP_/$vsc_floating_ip/g" ../environment/main.tf

echo "Modifying provider.tf files."
find ../* -name "*provider.tf" -exec sed -i "s/_OS_CLOUD_/$OS_CLOUD/g" {} \;

echo
echo "SSH commands for VMs access:"
echo
echo "(${VM_BASE_NAME})           ssh -p $ssh_forwarded_port1 <user>@$floating_ip"
echo "(${VM_BASE_NAME}-nginx)     ssh -p $ssh_forwarded_port2 <user>@$floating_ip"
echo "(${VM_BASE_NAME}-vsc_net)   ssh -p $ssh_forwarded_port3 <user>@$floating_ip"
echo "(${VM_BASE_NAME}-nfs_share) ssh -p $ssh_forwarded_port4 <user>@$floating_ip"
echo "(${VM_BASE_NAME}-windows)   xfreerdp /u:admin /port:${ssh_forwarded_port5} /v:${floating_ip}"
echo
