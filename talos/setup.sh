#!/bin/bash

set -e

# Variables
BASE_DIR=$(readlink -f $(dirname ${0}))
OUT_DIR="${BASE_DIR}/_out"
CONTROLPLANES_DIR="${OUT_DIR}/controlplanes"
WORKERS_DIR="${OUT_DIR}/workers"
CLUSTER_CONFIG_DIR="${OUT_DIR}/cluster-config"

CLUSTER_NAME="homelab-cluster"
CONTROL_PLANE_NODES=("192.168.1.103" "192.168.1.104" "192.168.1.105")
VIRTUAL_IP_ADDRESS="192.168.1.200"
NETWORK_GATEWAY="192.168.1.1" # For now presuming there is only one

# Generate secrets if the file doesn't exist
if [ ! -f "${CLUSTER_CONFIG_DIR}/secrets.yaml" ]; then
    echo "Generating Talos secrets..."
    mkdir -p "${CLUSTER_CONFIG_DIR}"
    talosctl gen secrets --output-file "${CLUSTER_CONFIG_DIR}/secrets.yaml"
fi

# Delete existing configs
for dir in "$CONTROLPLANES_DIR" "$WORKERS_DIR"; do
    if [ -d "$dir" ]; then
        rm -r "$dir"
    fi
done

# Generate controlplane configs
count=1
for i in "${CONTROL_PLANE_NODES[@]}"; do
    output_file="${CONTROLPLANES_DIR}/controlplane-${count}.yaml"

    echo "Generating controlplane-${count}.yaml for node ${node_ip}..."

    # network_interface=$(talosctl get links --insecure -o json --nodes $i | jq -r 'select(.spec.operationalState == "up") | .metadata.id')
    # network_mtu=$(talosctl get links --insecure -o json --nodes $i | jq -r 'select(.spec.operationalState == "up") | .spec.mtu')

    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/cluster-patch.yaml" \
        --output-types controlplane \
        --output "${output_file}"

    sed -i "s/NODE_HOSTNAME/talos-cp-$count/g" ${output_file}
    sed -i "s/VIRTUAL_IP_ADDRESS/${VIRTUAL_IP_ADDRESS}/g" ${output_file}
    sed -i "s/NODE_IP_ADDRESS/${i}/g" ${output_file}

    talosctl get disks --insecure -o table --nodes $i
    read -p "Enter the device to use for talos-cp-$count (e.g. /dev/sda) — WARNING: it will be completely wiped: " chosen_disk
    sed -i "s|NODE_DISK_DEVICE|${chosen_disk}|g" ${output_file}


    ((count++))

done

# Generate talosconfig
if [ ! -f "${CLUSTER_CONFIG_DIR}/talosconfig" ]; then
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/cluster-patch.yaml" \
        --output-types talosconfig \
        --output "${CLUSTER_CONFIG_DIR}"/talosconfig
fi