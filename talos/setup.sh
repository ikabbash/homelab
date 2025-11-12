#!/bin/bash

set -e

BASE_DIR=$(readlink -f $(dirname ${0}))
CLUSTER_NAME="homelab-cluster"
OUT_DIR="${BASE_DIR}/_out/${CLUSTER_NAME}"
CONTROLPLANES_DIR="${OUT_DIR}/controlplanes"
WORKERS_DIR="${OUT_DIR}/workers"
CLUSTER_CONFIG_DIR="${OUT_DIR}/cluster-config"
TALOS_CONFIG="${CLUSTER_CONFIG_DIR}"/talosconfig
KUBE_CONFIG="${CLUSTER_CONFIG_DIR}"/kubeconfig

PATCH_FILE="${BASE_DIR}/cluster-patch.yaml"
VIRTUAL_IP_ADDRESS="192.168.1.200"
NETWORK_GATEWAY="192.168.1.1" # Presuming there is only one

CONTROL_PLANE_NODES=("192.168.1.106")
# WORKER_NODES=("192.168.1.104" "192.168.1.105")

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

# Check if the cluster is just a single control plane node
if [ ${#CONTROL_PLANE_NODES[@]} -eq 1 ]; then
    VIRTUAL_IP_ADDRESS="${CONTROL_PLANE_NODES[0]}"
    PATCH_FILE="${BASE_DIR}/single-node-patch.yaml"
fi

# Generate talosconfig
if [ ! -f "${CLUSTER_CONFIG_DIR}/talosconfig" ]; then
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/cluster-patch.yaml" \
        --output-types talosconfig \
        --output "${TALOS_CONFIG}"
    
    talosctl --talosconfig="${TALOS_CONFIG}" config endpoints "${VIRTUAL_IP_ADDRESS}"
    talosctl --talosconfig="${TALOS_CONFIG}" config node "${VIRTUAL_IP_ADDRESS}"
fi

# Generate controlplane configs
count=1
for i in "${CONTROL_PLANE_NODES[@]}"; do    
    output_file="${CONTROLPLANES_DIR}/controlplane-${count}.yaml"
    echo "Generating controlplane-${count}.yaml for node ${node_ip}..."
    
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
            --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
            --config-patch-control-plane @"${PATCH_FILE}" \
            --output-types controlplane \
            --output "${output_file}"
    
    sed -i "s/NODE_HOSTNAME/talos-cp-${count}/g" ${output_file}
    sed -i "s/VIRTUAL_IP_ADDRESS/${VIRTUAL_IP_ADDRESS}/g" ${output_file}
    sed -i "s/NODE_IP_ADDRESS/${i}/g" ${output_file}

    if ! talosctl get disks --insecure -o table --nodes "${i}" 2>/dev/null; then
        talosctl get disks --talosconfig "$TALOS_CONFIG" -o table --nodes "${i}" || exit 1
    fi
    read -p "Enter the device to use for talos-cp-${count} (e.g. /dev/sda) — WARNING: it will be completely wiped: " chosen_disk
    sed -i "s|NODE_DISK_DEVICE|${chosen_disk}|g" ${output_file}

    ((count++))
done

# Generate kubeconfig
if [ ! -f "${CLUSTER_CONFIG_DIR}/kubeconfig" ]; then
    talosctl --talosconfig "${TALOS_CONFIG}" kubeconfig "${KUBE_CONFIG}"
fi