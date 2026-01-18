# Talos Linux
The homelab runs on [Talos Linux](https://www.talos.dev/), an OS designed specifically for Kubernetes. It is lightweight, immutable, and secure, with a focus on minimal attack surface and automated management. Talos Linux is configured entirely through an API, eliminating the need for direct SSH access or manual configuration.

If you want to learn more about Talos Linux, you can check this [cheat sheet](https://ikabbash.notion.site/Talos-Linux-299cab751076802a8b1ee963ecb7d8fb).

## Initial Setup
To set up your cluster with Talos Linux, generate the configuration using `talosctl gen config`, which creates the necessary control plane and worker configs along with keys. A helper script is available to automate this process, allowing you to specify the number of control planes and workers. When deploying multiple control planes, the script automatically configures a Virtual IP (VIP) for high availability.

The Virtual IP ([VIP](https://docs.siderolabs.com/talos/v1.11/networking/vip)) serves as a single, stable network address for the cluster’s control plane. It ensures that clients and worker nodes can always reach the API server at the same IP, even if individual control plane nodes go down, enabling seamless failover and high availability.

The `cluster-patch.yaml` file is used as a strategic merge patch when generating configs, which lets you declaratively inject all your custom cluster and machine settings (networking, DNS, kernel params, etc.) into the configs while generating. This ensures reproducible and consistent configs for all nodes.

Note that it's assumed that the DHCP server is configured to assign fixed IPs to the nodes based on their MAC addresses. You're welcome to make any changes to the `cluster-patch.yaml`.

Note that the PodSecurity admission defaults are already set to restricted for all audit, enforce, and warn levels. To check after installation, execute the command below.
```bash
talosctl get admissioncontrolconfigs.kubernetes.talos.dev admission-control -o yaml
```

### Requirements
Make sure the following are installed and accessible:
- `talosctl`: For generating and managing Talos cluster configurations
- `yq`: For editing YAML files from the command line (used by the `talos-config-gen.sh` script)

You may need to update the following variables in the script:
- `CLUSTER_NAME`: Your desired cluster name
- `VIRTUAL_IP_ADDRESS`: The cluster API VIP for high availability (if you'll have more than one control plane node)
- `CONTROL_PLANE_NODES`: An array of control plane node IPs
- `WORKER_NODES`: An array of worker node IPs

The script includes logic for cases such as enabling workload scheduling on control planes when no workers exist, and setting up the VIP when multiple control planes are present.

After running the setup script, your directory structure should look similar to the example below:
```
_out
└── homelab-cluster
    ├── cluster-config
    │   ├── secrets.yaml
    │   └── talosconfig
    ├── controlplanes
    │   ├── controlplane-1.yaml
    │   ├── controlplane-2.yaml
    │   └── controlplane-n.yaml
    └── workers
        ├── worker-1.yaml
        ├── worker-2.yaml
        └── worker-n.yaml
```

Make sure each node is running the Talos ISO because the script will prompt you to choose the installation disk for each one.

### Storage Configuration
To have persistent data on a node, you must define a [`UserVolumeConfig` ](https://docs.siderolabs.com/talos/v1.12/reference/configuration/block/uservolumeconfig). This configuration provisions a volume from a specified disk for user-defined data.

If you plan to use the same disk for both Talos and `UserVolumeConfig`, you must explicitly define a size limit for the [`EPHEMERAL`](https://docs.siderolabs.com/talos/v1.12/configure-your-talos-cluster/storage-and-disk-management/disk-management/system#ephemeral-volume) partition. By default, Talos allocates the entire disk to the `EPHEMERAL` partition (assuming you have another disk for storing data), which is used for storing container images, node logs, and etcd data (on control plane nodes).

Important: This configuration must be applied during the initial installation of Talos, as it involves disk partitioning. It cannot be applied to a node that is already running.

It is recommended to append the following configuration at the end of each node's config file (if you're planning to use the same disk for both cases that is).
```yaml
---
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

After Talos is installed and the node has booted, you can confirm both volumes were provisioned correctly using `talosctl get volumestatus` (after finishing the next steps, that is).

### Applying Configs
After you've generated your nodes' configs using `talos-config-gen.sh`, you'll be installing Talos on each node using `talosctl apply-config`.

You can run the commands below if you want easier access while working with the cluster. It’s up to you whether you prefer using these environment variables or merging the `talosconfig` and `kubeconfig` into your home directory:
```bash
export CLUSTER_NAME=homelab-staging
export TALOSCONFIG=/path/to/_out/${CLUSTER_NAME}/cluster-config/talosconfig
export KUBECONFIG=/path/to/_out/${CLUSTER_NAME}/cluster-config/kubeconfig
```

Apply configs on the first control plane node:
```bash
talosctl apply-config --insecure \
  --nodes $CONTROL_PLANE1_IP \
  --file _out/$CLUSTER_NAME/controlplanes/controlplane-1.yaml
```

After Talos has been installed on the first node and is in the booting stage, initialize the cluster (run this only once on the first control plane). The bootstrap command initializes etcd and starts the control plane pods:
```bash
talosctl bootstrap --nodes $CONTROL_PLANE1_IP --endpoints $CONTROL_PLANE1_IP
```

Confirm that etcd is running:
```bash
talosctl --nodes $CONTROL_PLANE1_IP etcd status
```

If you have more than one control plane node, apply the configs for the remaining ones:
```bash
talosctl apply-config --insecure \
  --nodes $CONTROL_PLANE2_IP \
  --file _out/$CLUSTER_NAME/controlplanes/controlplane-2.yaml

talosctl apply-config --insecure \
  --nodes $CONTROL_PLANE3_IP \
  --file _out/$CLUSTER_NAME/controlplanes/controlplane-3.yaml
```

Check that all nodes are healthy:
```bash
talosctl --nodes $CONTROL_PLANE1_IP,$CONTROL_PLANE2_IP,$CONTROL_PLANE3_IP health
```

Generate kubeconfig file and access the cluster:
```bash
talosctl kubeconfig $KUBECONFIG

kubectl get nodes
```

You'll find that all nodes show `NotReady` and CoreDNS pods are stuck on pending because we haven't installed a CNI yet which we will do.

If you have worker nodes, finally apply the configs and add them:
```bash
talosctl apply-config --insecure \
  --nodes $WORKER1_IP \
  --file _out/$CLUSTER_NAME/controlplanes/worker-1.yaml

talosctl apply-config --insecure \
  --nodes $WORKER2_IP \
  --file _out/$CLUSTER_NAME/controlplanes/worker-2.yaml

# Check that they're part of the cluster
kubectl get nodes
```

Next, you’ll set up the CNI and platform components. Apply the [Terraform](../terraform/README.md) configuration to deploy the CNI along with components like cert-manager, Argo CD, and others.

### Commands
```bash
# Shows dashboard
talosctl dashboard

# Retrieves the status of node system services
talosctl --nodes $NODE_IP_ADDRESS services

# Retrieves logs of target service
talosctl --nodes $NODE_IP_ADDRESS logs service_name

# Lists all containers in the containerd namespace (with -k)
talosctl --nodes $NODE_IP_ADDRESS containers -k

# Checks volume status
talosctl get volumestatus

# Checks volume location usage (obtained from volumestatus)
talosctl usage -H /dev/sdaX
```