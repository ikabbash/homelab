#!/bin/bash

# For single control plane node use only

set -e

NODE_IP="${1:?Usage: $0 <node-ip> [hostname] [disk]}"
NODE_HOSTNAME="${2:-talos-cp-1}"
# talosctl get disks --insecure -n <ip>
NODE_DISK="${3:-/dev/sda}"
NODE_TYPE="${4:-controlplane}"
CLUSTER_NAME="homelab-cluster"
CLUSTER_CONFIG_PATH="_out/${CLUSTER_NAME}"
CLUSTER_PATCH_PATH="${CLUSTER_CONFIG_PATH}/cluster-patch"
TALOSCONFIG="${CLUSTER_CONFIG_PATH}"/talosconfig

mkdir -p "${CLUSTER_CONFIG_PATH}"

talosctl gen secrets --output-file "${CLUSTER_CONFIG_PATH}"/secrets.yaml || true

if [[ ! -f "${CLUSTER_PATCH_PATH}" ]]; then
  cp -r cluster-patch "${CLUSTER_PATCH_PATH}"
fi

sed -i \
  -e "s|NODE_IP_ADDRESS|$NODE_IP|g" \
  -e "s|NODE_HOSTNAME|$NODE_HOSTNAME|g" \
  -e "s|NODE_DISK_DEVICE|$NODE_DISK|g" \
  "${CLUSTER_PATCH_PATH}"/01-machine-config.yaml

if [[ ! -f "${TALOSCONFIG}" && "${NODE_TYPE}" == "controlplane" ]]; then
  talosctl gen config "${CLUSTER_NAME}" "https://$NODE_IP:6443" \
    --with-secrets "${CLUSTER_CONFIG_PATH}/secrets.yaml" \
    --output-types talosconfig \
    --output "${TALOSCONFIG}"
fi

# Generate config
talosctl gen config "${CLUSTER_NAME}" "https://$NODE_IP:6443" \
  --with-secrets ${CLUSTER_CONFIG_PATH}/secrets.yaml \
  --config-patch-control-plane @"${CLUSTER_PATCH_PATH}"/01-machine-config.yaml \
  --config-patch-control-plane @"${CLUSTER_PATCH_PATH}"/02-network.yaml \
  --config-patch-control-plane @"${CLUSTER_PATCH_PATH}"/03-security.yaml \
  --config-patch-control-plane @"${CLUSTER_PATCH_PATH}"/04-kernel.yaml \
  --output-types controlplane \
  --output "${CLUSTER_CONFIG_PATH}"/"${NODE_HOSTNAME}".yaml \
  --force

talosctl validate \
  --config "${CLUSTER_CONFIG_PATH}"/"${NODE_HOSTNAME}".yaml \
  --mode metal

talosctl --talosconfig "${TALOSCONFIG}" config endpoints "${NODE_IP}"

talosctl --talosconfig "${TALOSCONFIG}" config node "${NODE_IP}"