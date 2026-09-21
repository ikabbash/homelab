# Talos Linux
The current Talos setup uses a script that generates config for a node at a time. This isn't as scalable as the [old multi-node setup](./deprecated/README.md) due to new changes and deprecations across versions, so keeping the generation process simple and manual per-node makes it easier to reason about when something changes.

Note: as of September 2026, [OpenEBS's Mayastor-on-Talos guide](https://openebs.io/docs/Solutioning/openebs-on-kubernetes-platforms/talos) is stale and likely incompatible, it relies on kubelet `extraMounts`, which no longer exists as of Talos 1.14+:
```yaml
machine:
  kubelet:
    disableManifestsDirectory: true
    extraMounts:
      - destination: /var/local
        type: bind
        source: /var/local
        options:
          - bind
          - rshared
          - rw
```

## Initial Setup
Download a Talos image from the [Image Factory](https://factory.talos.dev/) with the `util-linux-tools` extension (and `vmtoolsd-guest-agent` if running under VMware). The DHCP server is assumed to hand out fixed IPs per MAC address.

Config is assembled from a base `talosctl gen config` but you can use `talos-config-gen.sh` script which applies a set of patch files:
```
cluster-patch
├── 01-machine-config.yaml
├── 02-network.yaml
├── 03-security.yaml
└── 04-kernel.yaml
```

A few defaults worth knowing:
- `imageMaximumGCAge` is set to 30 days, unused images older than that get garbage collected. A kubelet restart resets the tracked age, so a freshly-restarted kubelet waits out the full 30 days again before anything qualifies.
- PodSecurity admission already defaults to `restricted` for enforce/audit/warn. Verify post-install with:
  ```bash
  talosctl get admissioncontrolconfigs.kubernetes.talos.dev admission-control -o yaml
  ```

If a control plane or worker node needs non-default storage, add a `VolumeConfig`/`UserVolumeConfig` patch, e.g.:
```yaml
apiVersion: v1alpha1
kind: VolumeConfig
name: EPHEMERAL
provisioning:
  diskSelector:
    match: disk.dev_path == "/dev/sda"
  maxSize: 20GiB
  grow: false
---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: homelab
volumeType: partition
provisioning:
  diskSelector:
    match: disk.dev_path == "/dev/sda"
  maxSize: "25GiB"
filesystem:
  type: xfs
```

Multiple nodes beyond what the script covers need manual edits per Talos' own docs, the script here only generates one node's config at a time.

## `talos-config-gen.sh`

Requires `talosctl` installed. Usage:
```bash
./talos-config-gen.sh <node-ip> [hostname] [disk] [node-type]
```

- `NODE_IP` (required): the node's static IP, also used as the cluster endpoint (`https://$NODE_IP:6443`).
- `NODE_HOSTNAME` (default `talos-cp-1`): used as the output filename and substituted into the machine config patch.
- `NODE_DISK` (default `/dev/sda`): install disk, check available disks first with `talosctl get disks --insecure -n <ip>`.
- `NODE_TYPE` (default `controlplane`): only gates whether a `talosconfig` gets generated, the script otherwise always renders control-plane patches.

Output:
```
_out/homelab-cluster
├── cluster-patch
│ ├── 01-machine-config.yaml
│ ├── 02-network.yaml
│ ├── 03-security.yaml
│ └── 04-kernel.yaml
├── secrets.yaml
├── talosconfig
└── talos-cp-1.yaml
```

## Applying Configs
Optionally export these for convenience instead of merging `talosconfig`/`kubeconfig` into your home dir:
```bash
export CLUSTER_NAME=homelab-cluster
export TALOSCONFIG=/path/to/_out/${CLUSTER_NAME}/talosconfig
export KUBECONFIG=/path/to/_out/${CLUSTER_NAME}/kubeconfig
export NODE_IP="192.168.1.5"
```

Apply to the first control plane node, then bootstrap the cluster (bootstrap only runs once, it initializes etcd and starts the control plane pods):
```bash
talosctl apply-config --insecure --nodes $NODE_IP --file /path/to/_out/$CLUSTER_NAME/talos-cp-1.yaml
talosctl bootstrap --nodes $NODE_IP --endpoints $NODE_IP
talosctl --nodes $NODE_IP etcd status
```

Additional control plane nodes get the same `apply-config`, each against its own generated file:
```bash
talosctl apply-config --insecure --nodes <cp-node2-ip> --file /path/to/_out/$CLUSTER_NAME/talos-cp-2.yaml
talosctl apply-config --insecure --nodes <cp-node3-ip> --file /path/to/_out/$CLUSTER_NAME/talos-cp-3.yaml
talosctl --nodes <cp-node1-ip>,<cp-node2-ip> health
```

Generate the kubeconfig and check node status:
```bash
talosctl kubeconfig $KUBECONFIG
kubectl get nodes
```

All nodes show `NotReady` and CoreDNS pods stay `Pending` at this point because no CNI is installed yet.

Apply worker configs if any, then confirm they've joined:
```bash
talosctl apply-config --insecure --nodes $WORKER1_IP --file _out/$CLUSTER_NAME/controlplanes/worker-1.yaml
talosctl apply-config --insecure --nodes $WORKER2_IP --file _out/$CLUSTER_NAME/controlplanes/worker-2.yaml
kubectl get nodes
```

CNI and platform components (cert-manager, Argo CD, etc.) come next via the [Terraform](../terraform/README.md) config.

## Useful Commands
```bash
# Dashboard
talosctl dashboard

# Node system service status
talosctl --nodes $NODE_IP_ADDRESS services

# Logs for a specific service
talosctl --nodes $NODE_IP_ADDRESS logs service_name

# List containers in the containerd namespace
talosctl --nodes $NODE_IP_ADDRESS containers -k

# Volume / mount status
talosctl get volumestatus
talosctl get mountstatus

# Volume usage (path from volumestatus)
talosctl usage -H /var/mnt/homelab
```