#!/bin/bash
set -ex
ports=()
count="$PORT_COUNT"
ip_id="$IP_ID"
port_name="$PORT_NAME"

[ -z ${OS_CLOUD+x} ] && echo "Variable OS_CLOUD is not set. Using openstack as a value." && export OS_CLOUD=openstack


generate_new_free_port () {
  column="External Port"
  allocated_ports=$(openstack floating ip port forwarding list "$ip_id" -f value -c "$column" --sort-column "$column")
  for i in $(seq 100); do
    port="$(shuf -i 51001-59999 -n 1)"
    if [[ ! " ${ports[*]} " =~ " ${port} " ]] && [[ ! " $allocated_ports " =~ " $port " ]]; then
        ports+=($port)
        break
    fi
  done
}

for i in $(seq 1 $count); do
    generate_new_free_port
done

echo "{\"ports\": $(jq --compact-output --null-input '$ARGS.positional' --args -- "${ports[@]}")}" > port_${port_name}.json

