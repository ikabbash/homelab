#!/bin/bash

set -e

# Variables
BASE_DIR=$(readlink -f $(dirname ${0}))
OUT_DIR="${BASE_DIR}/_out"
CONTROLPLANES_DIR="${OUT_DIR}/controlplanes"
WORKERS_DIR="${OUT_DIR}/workers"
CLUSTER_CONFIG_DIR="${OUT_DIR}/cluster-config"

CLUSTER_NAME="homelab-cluster"
VIRTUAL_IP_ADDRESS="192.168.1.200"
NETWORK_GATEWAY="192.168.1.1" # For now presuming there is only one

# Check if at least one IP was provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <IP1> [IP2] [IP3] ..."
    exit 1
fi
# Store all arguments in an array
CONTROL_PLANE_NODES=("$@")

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
if [ ${#CONTROL_PLANE_NODES[@]} -eq 1 ]; then
    node_ip="${CONTROL_PLANE_NODES[0]}"
    output_file="${CONTROLPLANES_DIR}/controlplane-1.yaml"

    echo "Generating controlplane-1.yaml for node ${node_ip}..."

    talosctl gen config "${CLUSTER_NAME}" "https://${node_ip}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/single-node-patch.yaml" \
        --output-types controlplane \
        --output "${output_file}"

    sed -i "s/NODE_HOSTNAME/talos-cp-1/g" ${output_file}
    sed -i "s/NODE_IP_ADDRESS/${node_ip}/g" ${output_file}

    talosctl get disks --insecure -o table --nodes ${node_ip}
    read -p "Enter the device to use for talos-cp-1 (e.g. /dev/sda) — WARNING: it will be completely wiped: " chosen_disk
    sed -i "s|NODE_DISK_DEVICE|${chosen_disk}|g" ${output_file}

else
    count=1
    for i in "${CONTROL_PLANE_NODES[@]}"; do
        output_file="${CONTROLPLANES_DIR}/controlplane-${count}.yaml"

        echo "Generating controlplane-${count}.yaml for node ${node_ip}..."

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
fi
# Generate talosconfig
if [ ! -f "${CLUSTER_CONFIG_DIR}/talosconfig" ]; then
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/cluster-patch.yaml" \
        --output-types talosconfig \
        --output "${CLUSTER_CONFIG_DIR}"/talosconfig
fi