#!/bin/bash

set -e

BASE_DIR=$(readlink -f $(dirname ${0}))
CLUSTER_NAME="homelab-cluster"
OUT_DIR="${BASE_DIR}/_out/${CLUSTER_NAME}"
CONTROLPLANES_DIR="${OUT_DIR}/controlplanes"
WORKERS_DIR="${OUT_DIR}/workers"
CLUSTER_CONFIG_DIR="${OUT_DIR}/cluster-config"
TALOSCONFIG="${CLUSTER_CONFIG_DIR}"/talosconfig

PATCH_FILE="${BASE_DIR}/cluster-patch.yaml"
VIRTUAL_IP_ADDRESS="192.168.1.200"
NETWORK_GATEWAY="192.168.1.1" # Presuming there is only one

CONTROL_PLANE_NODES=("192.168.1.107")
# WORKER_NODES=("192.168.1.104")

# Generate secrets if the file doesn't exist
if [ ! -f "${CLUSTER_CONFIG_DIR}/secrets.yaml" ]; then
    echo "Generating Talos secrets..."
    mkdir -p "${CLUSTER_CONFIG_DIR}"
    talosctl gen secrets --output-file "${CLUSTER_CONFIG_DIR}/secrets.yaml"
    echo
fi

# Delete existing configs
rm -rf "$CONTROLPLANES_DIR" "$WORKERS_DIR"

# Check if the cluster is just a single control plane node
if [ ${#CONTROL_PLANE_NODES[@]} -eq 1 ]; then
    VIRTUAL_IP_ADDRESS="${CONTROL_PLANE_NODES[0]}"
fi

# Generate talosconfig
if [ ! -f "${CLUSTER_CONFIG_DIR}/talosconfig" ]; then
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
        --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
        --config-patch-control-plane @"${BASE_DIR}/cluster-patch.yaml" \
        --output-types talosconfig \
        --output "${TALOSCONFIG}" \
        --force
    echo
    
    talosctl --talosconfig="${TALOSCONFIG}" config endpoints "${VIRTUAL_IP_ADDRESS}"
    talosctl --talosconfig="${TALOSCONFIG}" config node "${VIRTUAL_IP_ADDRESS}"
fi

# Prompt user to select disk within the node (added in the for loops for config generations)
select_disk_for_node() {
    local node_ip="$1"
    local node_count="$2"
    local output_file="$3"

    if ! talosctl get disks --insecure -o table --nodes "${node_ip}" 2>/dev/null; then
        talosctl get disks --talosconfig "$TALOSCONFIG" -o table --nodes "${node_ip}" || exit 1
    fi

    read -p "Enter the device to use for talos-cp-${node_count} (e.g. /dev/sda) — WARNING: it will be completely wiped: " chosen_disk
    sed -i "s|NODE_DISK_DEVICE|${chosen_disk}|g" "${output_file}"
}

# Generate control plane configs
count=1
for node_ip in "${CONTROL_PLANE_NODES[@]}"; do
    output_file="${CONTROLPLANES_DIR}/controlplane-${count}.yaml"
    echo "Generating controlplane-${count}.yaml for node ${node_ip}..."
    
    # Generate control plane configs
    talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
            --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
            --config-patch-control-plane @"${PATCH_FILE}" \
            --output-types controlplane \
            --output "${output_file}"
    echo

    # Add VIP configs if there's more than one control plane node, else clear comments in the yaml file
    if [ ${#CONTROL_PLANE_NODES[@]} -gt 1 ]; then
        yq -i -y '.machine.network.interfaces[0].vip.ip = "VIRTUAL_IP_ADDRESS"' "${output_file}"
        yq -i -y '.machine.certSANs += ["VIRTUAL_IP_ADDRESS"]' "${output_file}"
    else
        yq -i -y '.' "${output_file}"
    fi

    # If there are no workers, make control planes schedulable
    if [ -z "${WORKER_NODES+x}" ] || [ "${#WORKER_NODES[@]}" -eq 0 ]; then
        yq -i -y '.cluster.allowSchedulingOnControlPlanes = true' "${output_file}"
    fi

    sed -i "s/NODE_HOSTNAME/talos-cp-${count}/g" ${output_file}
    sed -i "s/VIRTUAL_IP_ADDRESS/${VIRTUAL_IP_ADDRESS}/g" ${output_file}
    sed -i "s/NODE_IP_ADDRESS/${node_ip}/g" ${output_file}

    select_disk_for_node "${node_ip}" "${count}" "${output_file}"

    ((count++))
done

# Generate worker configs
if [[ -n "${WORKER_NODES}" ]]; then
    count=1
    # Generate worker configs
    for node_ip in "${WORKER_NODES[@]}"; do
        output_file="${WORKERS_DIR}/worker-${count}.yaml"
        echo "Generating worker-${count}.yaml for node ${node_ip}..."

        talosctl gen config "${CLUSTER_NAME}" "https://${VIRTUAL_IP_ADDRESS}:6443" \
            --with-secrets "${CLUSTER_CONFIG_DIR}/secrets.yaml" \
            --config-patch-worker @"${PATCH_FILE}" \
            --output-types worker \
            --output "${output_file}"
        echo

        # Remove unneeded configs
        yq -i -y '.machine.certSANs = []' "${output_file}"
        yq -i -y 'del(.machine.features.kubernetesTalosAPIAccess)' "${output_file}"

        sed -i "s/NODE_HOSTNAME/talos-worker-${count}/g" ${output_file}

        select_disk_for_node "${node_ip}" "${count}" "${output_file}"

        ((count++))
    done
fi